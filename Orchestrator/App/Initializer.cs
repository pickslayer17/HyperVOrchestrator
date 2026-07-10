using Orchestrator.Config;
using Orchestrator.Core;
using Orchestrator.Models.NetWorkModels;

namespace Orchestrator.App;

internal sealed class Initializer
{
    private readonly RunScriptManager _runManager;

    public Initializer(RunScriptManager runManager)
    {
        _runManager = runManager;
    }

    public Host Run(Action<string> onLine)
    {
        var state = _runManager.StateKeeper;
        var config = AppConfig.Load(Program.RepoRoot);

        //[DONE] create NetWorkModels folder in Models folder
        //[DONE] all new models execpt executor models are moving to Models/NetWorkModels
        var host = new Host();
        state.SetCurrentHost(host);

        //[DONE] need to check inf natsdwitch and nat net exist and get existing one.
        //[DONE] config is for new net only .
        //[DONE] before GetHostNatSwitch - need to add step to check if exists.
        //[DONE] so no need to check in _system scripts anymore - all checks will be here - in C#
        //[DONE] host.NexExecutor.GetHostNatSwitch()
        if (host.NetExecutor.NatExists(config.Network.NatName))
            host.NatNet = new Net { Alias = host.NetExecutor.GetHostNatSwitch() };

        //[DONE] all methods which work with _system scripts - are going to NexEcecutor or PythonServer.Python
        //[DONE] it depends on who performs the action
        host.SwitchName = config.Network.SwitchName;

        //[DONE] host.NexExecutor.GetHostNatIP()
        host.NatNetInterface = new NetInterface { IP = host.NetExecutor.GetHostNatIP() };

        //[DONE] host.PythonServer.Python.GetProxyAlive();
        host.PythonServer.Alive = host.PythonServer.Python.GetProxyAlive();

        //[DONE] add method(and script to method) to get all vm on machine
        //[DONE] since we dont verify existing in scripts anymore - check should be here
        //[DONE] add foreach for all vmNames on host
        var actualVmNames = host.NetExecutor.GetVMNames();
        foreach (var vmName in actualVmNames)
        {
            var vm = new VM { Name = vmName };
            host.VMs.Add(vm);
        }

        //[DONE] in future we planning to choose the name of VM we want to work with
        var currentVmName = config.Vm.Name;
        var currentVm = host.VMs.First(vm => vm.Name == currentVmName);
        state.SetCurrentVm(currentVm);

        //[DONE] vm.NetExecutor.GetNetworkInfo() - I've changed proxyPort - to ProxyAddress in Probe mode
        //[DONE] renamed VmProbe to VmFSModel (rule: data from script comes in FSModel class); moved to FSModels
        var currentVmInfo = currentVm.NetExecutor.GetNetworkInfo();
        currentVm.Running = currentVmInfo.Running;

        //[DONE] NetInterface now has 3 fields -> separate vm.NetExecutor.GetNetInterfaceInfo() returning NetInterfaceFSModel
        var netInterfaceInfo = currentVm.NetExecutor.GetNetInterfaceInfo();
        currentVm.NatNetInterface = new NetInterface
        {
            IsDynamic = netInterfaceInfo.IsDynamic,
            Alias = netInterfaceInfo.Alias,
            IP = netInterfaceInfo.IP,
        };

        //[DONE] i renamed proxyPort to ProxyAddress
        currentVm.ProxyAddress = currentVmInfo.ProxyAddress;

        //[DONE] written from zero - new mechanism via host.PythonServer.Python.GetAllConnections()
        //[DONE] find forward connection for our machine by ip -> forward port
        //[DONE] no such connection -> leave empty, add nothing to FwdIpdsAndPorts
        //[DONE] FwdIpdsAndPorts moved inside PythonServer model
        var connections = host.PythonServer.Python.GetAllConnections();
        var vmIp = currentVm.NatNetInterface?.IP;
        var forward = connections?.Fwd?.FirstOrDefault(f =>
            !string.IsNullOrEmpty(vmIp) && f.Target.StartsWith(vmIp + ":"));
        if (forward is not null && int.TryParse(forward.Listen.Split(':').Last(), out var forwardPort))
            host.PythonServer.FwdIpdsAndPorts[vmIp!] = forwardPort;

        Print(state, onLine);
        return host;
    }

    private static void Print(StateKeeper state, Action<string> onLine)
    {
        var host = state.CurrentHost!;
        onLine($"[INIT] switch: {host.SwitchName}  nat: {(string.IsNullOrEmpty(host.NatNet?.Alias) ? "<none>" : host.NatNet.Alias)}  ip: {host.NatNetInterface?.IP}");
        onLine($"[INIT] VMs ({host.VMs.Count}):");

        var vm = state.CurrentVm!;
        onLine($"[INIT] {vm.Name}  running={vm.Running}  ip={vm.NatNetInterface?.IP}  alias={vm.NatNetInterface?.Alias}  proxy={vm.ProxyAddress}");
    }
}
