using Orchestrator.Config;
using Orchestrator.Core;
using global::Orchestrator.FSModels;
using Orchestrator.Models.NetWorkModels;
using System.Net;

namespace Orchestrator.App;

internal class NetworkSetup
{
    private readonly StateKeeper _stateKeeper;

    private Host _host => _stateKeeper.CurrentHost!;
    private VM _vm => _stateKeeper.CurrentVm!;

    public NetworkSetup(StateKeeper stateKeeper)
    {
        _stateKeeper = stateKeeper;
    }

    public void Configure()
    {
        foreach (var (_, action) in GetSteps())
            action();
    }

    public List<(string Name, Action Run)> GetSteps()
    {
        var network = AppConfig.Current.Network;

        return new List<(string, Action)>
        {
            ("Ensure NAT", () =>
            {
                EnsureNat(network.NatName, network.SwitchName, network.SubnetPrefixLength);
            }),
            ("Ensure host NAT IP", () =>
            {
                EnsureHostNatIp(network.SwitchName, network.DefaultNatHostIp, network.SubnetPrefixLength);
            }),
            ("Ensure VM connection", () =>
            {
                var currentSwitch = _host.NetExecutor.GetVmSwitchName();
                if (currentSwitch != network.SwitchName)
                    _host.NetExecutor.ConnectVmToNet(network.SwitchName);
            }),
            ("Set VM static IP", () =>
            {
                EnsureVmStaticIp(network.NatName, network.SubnetPrefixLength, network.DnsServer);
            }),
            ("Start Python server", () =>
            {
                StartPython();
            }),
            ("Ensure Python SOCKS proxy", () =>
            {
                EnsurePythonProxy(_host.NatNetInterface.IP);
            }),
            ("Ensure Python DNS proxy", () =>
            {
                EnsurePythonDns(_host.NatNetInterface.IP);
            }),
            ("Set SingBox config", SetSingBoxConfig),
            ("Restart SingBox", RestartSingBox),
        };
    }

    private void EnsureNat(string natName, string switchName, int prefixLength)
    {
        if (_host.NatNet == null)
        {
            var hostIp = GetHostNatIp(switchName);
            var netInfo = _host.NetExecutor.NatExists(natName)
                ? _host.NetExecutor.GetNetInfo(natName)
                : _host.NetExecutor.CreateNatNet(natName, switchName, hostIp, prefixLength);

            netInfo.HostNetInterface = _host.NetExecutor.GetHostNetInterfaceInfo(natName);
            _host.NatNet = netInfo;
            _host.NatNetInterface = netInfo.HostNetInterface;
        }
        if (_host.NatNet == null)
            throw new InvalidOperationException($"Nat '{natName}' is not available.");
    }

    private string GetHostNatIp(string switchName)
    {
        var existing = _host.NetExecutor.GetHostNatInterfaceInfo(switchName);
        if (!string.IsNullOrEmpty(existing.IP))
            return existing.IP;
        return AppConfig.Current.Network.DefaultNatHostIp;
    }

    private void EnsureHostNatIp(string switchName, string defaultIp, int prefixLength)
    {
        var current = _host.NetExecutor.GetHostNatInterfaceInfo(switchName);
        if (string.IsNullOrEmpty(current.Alias))
            throw new InvalidOperationException($"Host NAT interface for switch '{switchName}' was not found.");

        var ip = string.IsNullOrEmpty(current.IP) ? defaultIp : current.IP;
        if (string.IsNullOrEmpty(ip))
            throw new InvalidOperationException("Host NAT IP is not configured.");

        if (current.IsDynamic || string.IsNullOrEmpty(current.IP))
            _host.NetExecutor.SetHostStaticIp(current.Alias, ip, prefixLength);

        var actual = _host.NetExecutor.GetHostNatInterfaceInfo(switchName);
        if (actual.IsDynamic || actual.IP != ip)
            throw new InvalidOperationException($"Host NAT interface '{actual.Alias}' did not acquire static IP '{ip}'.");

        _host.NatNetInterface = new NetInterface
        {
            IsDynamic = actual.IsDynamic,
            Alias = actual.Alias,
            IP = actual.IP,
        };
        _host.NatNet.HostNetInterface = _host.NatNetInterface;
    }

    private void EnsureVmStaticIp(string natName, int prefixLength, string dns)
    {
        var gateway = _host.NatNetInterface.IP;
        var current = _vm.NetExecutor.GetNetInterfaceInfo();
        if (string.IsNullOrEmpty(current.Alias))
            throw new InvalidOperationException($"Vm '{_vm.Name}' is not connected to nat '{natName}'.");

        var ip = IsUsableVmIp(current.IP, gateway) ? current.IP : FindFreeIp(gateway);
        if (!IsVmNetworkConfigured(current, ip, gateway, prefixLength, dns))
            _vm.NetExecutor.SetStaticIp(current.Alias, ip, gateway, prefixLength, dns);

        var actual = _vm.NetExecutor.GetNetInterfaceInfo();
        if (!IsVmNetworkConfigured(actual, ip, gateway, prefixLength, dns))
            throw new InvalidOperationException($"Vm '{_vm.Name}' network configuration was not applied.");

        _vm.NatNetInterface = new NetInterface
        {
            IsDynamic = actual.IsDynamic,
            Alias = actual.Alias,
            IP = actual.IP,
        };
    }

    private static bool IsUsableVmIp(string ip, string gateway)
    {
        if (string.IsNullOrEmpty(ip) || string.IsNullOrEmpty(gateway) || ip == gateway)
            return false;
        var subnet = gateway[..(gateway.LastIndexOf('.') + 1)];
        return ip.StartsWith(subnet, StringComparison.Ordinal);
    }

    private static bool IsVmNetworkConfigured(
        NetInterfaceFSModel current,
        string ip,
        string gateway,
        int prefixLength,
        string dns)
    {
        return !current.IsDynamic
            && current.IP == ip
            && current.PrefixLength == prefixLength
            && current.Gateway == gateway
            && current.DnsServers.Count == 1
            && current.DnsServers[0].Equals(dns, StringComparison.OrdinalIgnoreCase);
    }

    private string FindFreeIp(string gateway)
    {
        var subnet = gateway[..(gateway.LastIndexOf('.') + 1)];
        for (var octet = 2; octet < 255; octet++)
        {
            var candidate = $"{subnet}{octet}";
            if (_host.NetExecutor.IsIpFree(candidate))
                return candidate;
        }
        throw new InvalidOperationException($"No free ip in subnet {subnet}0.");
    }

    private void StartPython()
    {
        if (!_host.PythonServer.PythonExecutor.IsAlive())
            _host.PythonServer.PythonExecutor.Start();

        LoadPythonServer();
        if (!_host.PythonServer.Alive)
            throw new InvalidOperationException("Python server did not become available after start.");
    }

    private void EnsurePythonProxy(string natIp)
    {
        LoadPythonServer();
        if (_host.PythonServer.ProxyConnections.Count > 0)
            return;

        var endpoint = new IPEndPoint(IPAddress.Parse(natIp), _host.NetExecutor.GetFreePort());
        _host.PythonServer.PythonExecutor.StartProxy(endpoint.Address.ToString(), endpoint.Port);
        LoadPythonServer();
        if (!_host.PythonServer.ProxyConnections.Contains(endpoint))
            throw new InvalidOperationException($"Python proxy '{endpoint}' was not created.");
    }

    private void EnsurePythonDns(string natIp)
    {
        LoadPythonServer();
        if (_host.PythonServer.DnsConnections.Count > 0)
            return;

        var endpoint = new IPEndPoint(IPAddress.Parse(natIp), _host.NetExecutor.GetFreeUdpPort());
        _host.PythonServer.PythonExecutor.StartDns(endpoint.Address.ToString(), endpoint.Port);
        LoadPythonServer();
        if (!_host.PythonServer.DnsConnections.ContainsKey(endpoint))
            throw new InvalidOperationException($"Python DNS proxy '{endpoint}' was not created.");
    }

    private void SetSingBoxConfig()
    {
        LoadPythonServer();
        var proxy = _host.PythonServer.ProxyConnections.FirstOrDefault()
            ?? throw new InvalidOperationException("Python SOCKS proxy is not available.");
        var dns = _host.PythonServer.DnsConnections.Keys.FirstOrDefault()
            ?? throw new InvalidOperationException("Python DNS proxy is not available.");
        _vm.SingBoxExecutor.SetConfig(_host.NatNetInterface.IP, proxy.Port, dns.Port);
        LoadSingBox();
    }

    private void RestartSingBox()
    {
        _vm.SingBoxExecutor.Restart();
        LoadSingBox();
    }

    private void LoadPythonServer()
    {
        var server = _host.PythonServer;
        server.Alive = server.PythonExecutor.IsAlive();
        var connections = server.Alive ? server.PythonExecutor.GetAllConnections() : new ConnectionsFSModel();
        server.ActiveConnections = connections.Active;
        server.ProxyConnections = connections.Proxy.Select(ParseEndpoint).ToList();
        server.DnsConnections = connections.Dns.ToDictionary(
            connection => ParseEndpoint(connection.Listen),
            connection => ParseEndpoint(connection.Target));
    }

    private void LoadSingBox()
    {
        var config = _vm.SingBoxExecutor.GetConfig();
        _vm.ProxyAddress = ParseOptionalEndpoint(config.ProxyAddress);
        _vm.DnsAddress = ParseOptionalEndpoint(config.DnsAddress);
        _vm.SingBoxRunning = config.Running;
    }

    private static IPEndPoint? ParseOptionalEndpoint(string value)
    {
        return string.IsNullOrWhiteSpace(value) ? null : ParseEndpoint(value);
    }

    private static IPEndPoint ParseEndpoint(string value)
    {
        if (!IPEndPoint.TryParse(value, out var endpoint))
            throw new InvalidOperationException($"Invalid endpoint '{value}'.");
        return endpoint;
    }
}
