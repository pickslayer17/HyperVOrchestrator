using Orchestrator.Config;
using Orchestrator.Models;

namespace Orchestrator.App;

public class NetworkSetup
{
    private readonly Host _host;
    private readonly AppConfig _config;

    public NetworkSetup(Host host, AppConfig config)
    {
        _host = host;
        _config = config;
    }

    public void Configure(VM vm)
    {
        var natNet = EnsureNat(_config.Network.NatName);
        SetStaticIps(natNet, vm);
        StartPython();
        var proxyPort = GetProxyPort(natNet);
        var proxyAddress = StartProxy(_host.NatNetInterface.IP, proxyPort);
        ApplyVmProxy(vm, proxyAddress);
        var forwardPort = GetForwardPort(_host.GlobalNetInterface);
        ForwardVmRdp(_config.Network.ForwardBind, forwardPort, vm.NatNetInterface.IP);
        EnableVmRdp(vm);
    }

    private Net EnsureNat(string natName)
    {
        if (_host.NatNet == null)
        {
            var netInfo = _host.NetExecutor.NatExists(natName)
                ? _host.NetExecutor.GetNetInfo(natName)
                : _host.NetExecutor.CreateNatNet(natName);

            netInfo.HostNetInterface = _host.NetExecutor.GetHostNetInterfaceInfo(natName);
            _host.NatNet = netInfo;
            _host.NatNetInterface = netInfo.HostNetInterface;
        }
        if (_host.NatNet == null)
            throw new InvalidOperationException($"Nat '{natName}' is not available.");

        return _host.NatNet;
    }

    private void SetStaticIps(Net natNet, VM vm)
    {
        _host.NetExecutor.SetStaticIp(natNet.Alias);
        vm.NatNetInterface = vm.NetExecutor.SetStaticIp(natNet.Alias);
    }

    private void StartPython()
    {
        if (!_host.PythonServer.Python.IsAlive())
            _host.PythonServer.Python.Start();
    }

    private int GetProxyPort(Net natNet)
    {
        return _host.NetExecutor.GetFreePort(natNet.Alias);
    }

    private string StartProxy(string natIp, int proxyPort)
    {
        _host.PythonServer.Python.StartProxy(natIp, proxyPort);
        return $"{natIp}:{proxyPort}";
    }

    private void ApplyVmProxy(VM vm, string proxyAddress)
    {
        vm.ProxyAddress = proxyAddress;
        vm.NetExecutor.SetProxy(proxyAddress);
    }

    private int GetForwardPort(NetInterface globalInterface)
    {
        return _host.NetExecutor.GetFreePort(globalInterface.Alias);
    }

    private void ForwardVmRdp(string bind, int forwardPort, string vmIp)
    {
        _host.PythonServer.Python.StartForward(bind, forwardPort, vmIp, 3389);
        _host.FwdIpdsAndPorts[vmIp] = forwardPort;
    }

    private void EnableVmRdp(VM vm)
    {
        vm.NetExecutor.EnableRdp();
    }
}
