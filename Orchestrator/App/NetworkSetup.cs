using Orchestrator.Config;
using Orchestrator.Core;
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
            ("Set host static IP", () =>
            {
                if (_host.NatNetInterface.IsDynamic)
                    SetHostStaticIp(network.SubnetPrefixLength, network.DnsServer);
            }),
            ("Ensure VM connection", () =>
            {
                var currentSwitch = _host.NetExecutor.GetVmSwitchName();
                if (currentSwitch != network.SwitchName)
                    _host.NetExecutor.ConnectVmToNet(network.SwitchName);
            }),
            ("Set VM static IP ", () =>
            {
                var gateway = _host.NatNetInterface.IP;
                var vmIp = FindFreeIp(gateway);
                var vmNetInterfaceInfo = _vm.NetExecutor.GetNetInterfaceInfo();
                _vm.NatNetInterface = new NetInterface
                {
                    IsDynamic = vmNetInterfaceInfo.IsDynamic,
                    Alias = vmNetInterfaceInfo.Alias,
                    IP = _host.NetExecutor.GetVmIp(),
                };
                if (string.IsNullOrEmpty(vmNetInterfaceInfo.Alias))
                    throw new InvalidOperationException($"Vm '{_vm.Name}' is not connected to nat '{network.NatName}'.");
                SetVmStaticIp(vmNetInterfaceInfo.Alias, vmIp, gateway, network.SubnetPrefixLength, network.DnsServer);
            }),
            ("Start python server", () =>
            {
                StartPython();
            }),
            ("Start proxy + apply to VM", () =>
            {
                var gateway = _host.NatNetInterface.IP;
                var proxyPort = GetHostFreePort(_host.NatNet.Alias);
                StartProxy(gateway, proxyPort);

                var proxyAddress = $"{gateway}:{proxyPort}";
                ApplyVmProxy(proxyAddress);
            }),
            ("Forward VM RDP", () =>
            {
                var forwardPort = GetHostFreePort(_host.GlobalNetInterface.Alias);
                ForwardVmRdp(network.ForwardBind, forwardPort, _vm.NatNetInterface.IP, 3389);
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
            var hostIp = GetHostNatIp();
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

    private string GetHostNatIp()
    {
        var existing = _host.NetExecutor.GetHostNatInterfaceInfo();
        if (!string.IsNullOrEmpty(existing.IP))
            return existing.IP;
        return AppConfig.Current.Network.DefaultNatHostIp;
    }

    private void SetHostStaticIp(int prefixLength, string dns)
    {
        _host.NatNetInterface = _host.NetExecutor.SetStaticIp(
            _host.NatNetInterface.Alias,
            _host.NatNetInterface.IP,
            _host.NatNetInterface.IP,
            prefixLength,
            dns);
        _host.NatNet.HostNetInterface = _host.NatNetInterface;
    }

    private void SetVmStaticIp(string alias, string vmIp, string gateway, int prefixLength, string dns)
    {
        _vm.NatNetInterface = _vm.NetExecutor.SetStaticIp(alias, vmIp, gateway, prefixLength, dns);
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
        _host.PythonServer.Alive = true;
    }

    private int GetHostFreePort(string netAias)
    {
        return _host.NetExecutor.GetFreePort(netAias);
    }

    private void StartProxy(string natIp, int proxyPort)
    {
        _host.PythonServer.Python.StartProxy(natIp, proxyPort);
    }

    private void ApplyVmProxy(string proxyAddress)
    {
        _vm.NetExecutor.SetProxy(proxyAddress, AppConfig.Current.Credentials.User);
        _vm.ProxyAddress = proxyAddress;
    }

    private void ForwardVmRdp(string bind, int forwardPort, string vmIp, int targetPort)
    {
        _host.PythonServer.Python.StartForward(bind, forwardPort, vmIp, targetPort);
        _host.PythonServer.FwdIpdsAndPorts[vmIp] = forwardPort;
    }

    private void EnableVmRdp()
    {
        _vm.NetExecutor.EnableRdp();
    }
}
