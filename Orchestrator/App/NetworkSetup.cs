using Orchestrator.Config;
using Orchestrator.Core;
using global::Orchestrator.FSModels;
using Orchestrator.Models.NetWorkModels;

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
            ("Ensure NAT.", () =>
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
            ("Set VM static IP ", () =>
            {
                EnsureVmStaticIp(network.NatName, network.SubnetPrefixLength, network.DnsServer);
            }),
            ("Start python server", () =>
            {
                StartPython();
            }),
            ("Start proxy + apply to VM", () =>
            {
                EnsureVmProxy(_host.NatNetInterface.IP);
            }),
            ("Forward VM RDP", () =>
            {
                EnsureVmRdpForward(network.ForwardBind, 3389);
            }),
            ("Enable RDP in VM", () =>
            {
                EnableVmRdp();
            }),
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
        if (!_host.PythonServer.Python.IsAlive())
            _host.PythonServer.Python.Start();

        _host.PythonServer.Alive = _host.PythonServer.Python.IsAlive();
        if (!_host.PythonServer.Alive)
            throw new InvalidOperationException("Python server did not become available after start.");
    }

    private int GetHostFreePort(string netAias)
    {
        return _host.NetExecutor.GetFreePort(netAias);
    }

    private void StartProxy(string natIp, int proxyPort)
    {
        _host.PythonServer.Python.StartProxy(natIp, proxyPort);
    }

    private void EnsureVmProxy(string gateway)
    {
        var vmInfo = _vm.NetExecutor.GetNetworkInfo();
        var configuredAddress = vmInfo.ProxyAddress.Trim();
        _vm.ProxyAddress = configuredAddress;

        var connections = _host.PythonServer.Python.GetAllConnections();
        if (TryParseEndpoint(configuredAddress, out var configuredIp, out var configuredPort)
            && configuredIp == gateway)
        {
            if (HasProxy(connections, configuredAddress))
                return;

            try
            {
                StartProxy(configuredIp, configuredPort);
                if (HasProxy(_host.PythonServer.Python.GetAllConnections(), configuredAddress))
                    return;
            }
            catch (InvalidOperationException)
            {
            }
        }

        var proxyPort = GetHostFreePort(_host.NatNet.Alias);
        var proxyAddress = $"{gateway}:{proxyPort}";
        StartProxy(gateway, proxyPort);
        if (!HasProxy(_host.PythonServer.Python.GetAllConnections(), proxyAddress))
            throw new InvalidOperationException($"Python proxy '{proxyAddress}' was not created.");
        ApplyVmProxy(proxyAddress);
    }

    private static bool HasProxy(ConnectionsFSModel connections, string address)
    {
        return connections.Proxy.Any(proxy => proxy.Equals(address, StringComparison.OrdinalIgnoreCase));
    }

    private void ApplyVmProxy(string proxyAddress)
    {
        _vm.NetExecutor.SetProxy(proxyAddress, AppConfig.Current.Credentials.User);
        var actualAddress = _vm.NetExecutor.GetNetworkInfo().ProxyAddress.Trim();
        if (!actualAddress.Equals(proxyAddress, StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException($"Vm '{_vm.Name}' proxy was not set to '{proxyAddress}'.");
        _vm.ProxyAddress = actualAddress;
    }

    private void EnsureVmRdpForward(string bind, int targetPort)
    {
        var vmIp = _vm.NetExecutor.GetNetInterfaceInfo().IP;
        if (string.IsNullOrEmpty(vmIp))
            throw new InvalidOperationException($"Vm '{_vm.Name}' has no IPv4 address for RDP forwarding.");

        var target = $"{vmIp}:{targetPort}";
        var connections = _host.PythonServer.Python.GetAllConnections();
        var existing = connections.Fwd.FirstOrDefault(forward =>
            forward.Target.Equals(target, StringComparison.OrdinalIgnoreCase)
            && TryParseEndpoint(forward.Listen, out var listenIp, out _)
            && listenIp == bind);
        if (existing is not null)
        {
            if (!TryParseEndpoint(existing.Listen, out _, out var existingPort))
                throw new InvalidOperationException($"Python returned invalid forward address '{existing.Listen}'.");
            _host.PythonServer.FwdIpdsAndPorts[vmIp] = existingPort;
            return;
        }

        var forwardPort = GetHostFreePort(_host.GlobalNetInterface.Alias);
        var listen = $"{bind}:{forwardPort}";
        _host.PythonServer.Python.StartForward(bind, forwardPort, vmIp, targetPort);

        var actual = _host.PythonServer.Python.GetAllConnections().Fwd.FirstOrDefault(forward =>
            forward.Listen.Equals(listen, StringComparison.OrdinalIgnoreCase)
            && forward.Target.Equals(target, StringComparison.OrdinalIgnoreCase));
        if (actual is null)
            throw new InvalidOperationException($"Python forward '{listen}' to '{target}' was not created.");
        _host.PythonServer.FwdIpdsAndPorts[vmIp] = forwardPort;
    }

    private static bool TryParseEndpoint(string endpoint, out string ip, out int port)
    {
        ip = "";
        port = 0;
        var separator = endpoint.LastIndexOf(':');
        if (separator <= 0 || separator == endpoint.Length - 1)
            return false;
        ip = endpoint[..separator];
        return int.TryParse(endpoint[(separator + 1)..], out port);
    }

    private void EnableVmRdp()
    {
        _vm.NetExecutor.EnableRdp();
    }
}
