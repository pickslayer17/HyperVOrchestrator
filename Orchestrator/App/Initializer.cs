using Orchestrator.Config;
using Orchestrator.Core;
using Orchestrator.Executors;
using Orchestrator.Models.NetWorkModels;

namespace Orchestrator.App;

internal sealed class Initializer
{
    private readonly RunScriptManager _runManager;

    public Initializer(RunScriptManager runManager)
    {
        _runManager = runManager;
    }

    public Host LoadHost()
    {
        var state = _runManager.StateKeeper;
        var config = AppConfig.Load(Program.RepoRoot);

        var host = new Host();
        state.SetCurrentHost(host);
        host.NetExecutor = new NetExecutor("Host") { RunManager = _runManager };
        host.HyperVExecutor = new HyperVExecutor { RunManager = _runManager };
        host.PythonServer.Python = new PythonExecutor { RunManager = _runManager };

        if (host.NetExecutor.NatExists(config.Network.NatName))
        {
            host.NatNet = new Net { Alias = host.NetExecutor.GetHostNatSwitch() };
            host.SwitchName = host.NetExecutor.GetSwitchName();

            var hostInterface = host.NetExecutor.GetHostNatInterfaceInfo();
            host.NatNetInterface = new NetInterface
            {
                IsDynamic = hostInterface.IsDynamic,
                Alias = hostInterface.Alias,
                IP = hostInterface.IP,
            };
        }

        host.PythonServer.Alive = host.PythonServer.Python.GetProxyAlive();

        if (!host.HyperVExecutor.IsHyperVExists())
            return host;

        var actualVmNames = host.HyperVExecutor.GetVMNames();
        foreach (var vmName in actualVmNames)
        {
            var vm = new VM { Name = vmName };
            vm.NetExecutor = new NetExecutor("VM") { RunManager = _runManager };
            host.VMs.Add(vm);
        }

        return host;
    }

    public void LoadVmInfo(VM vm)
    {
        var state = _runManager.StateKeeper;
        var host = state.CurrentHost!;
        state.SetCurrentVm(vm);

        var vmInfo = vm.NetExecutor.GetNetworkInfo();
        vm.Running = vmInfo.Running;
        vm.ProxyAddress = vmInfo.ProxyAddress;

        var netInterfaceInfo = vm.NetExecutor.GetNetInterfaceInfo();
        vm.NatNetInterface = new NetInterface
        {
            IsDynamic = netInterfaceInfo.IsDynamic,
            Alias = netInterfaceInfo.Alias,
            IP = host.NetExecutor.GetVmIp(),
        };

        var connections = host.PythonServer.Python.GetAllConnections();
        var vmIp = vm.NatNetInterface?.IP;
        var forward = connections?.Fwd?.FirstOrDefault(f =>
            !string.IsNullOrEmpty(vmIp) && f.Target.StartsWith(vmIp + ":"));
        if (forward is not null && int.TryParse(forward.Listen.Split(':').Last(), out var forwardPort))
            host.PythonServer.FwdIpdsAndPorts[vmIp!] = forwardPort;
    }
}
