using System.Text.Json;
using Orchestrator.Config;
using Orchestrator.Core;
using Orchestrator.Models;

namespace Orchestrator.App;

internal sealed class Initializer
{
    private static readonly JsonSerializerOptions JsonOptions =
        new() { PropertyNameCaseInsensitive = true };

    private readonly RunScriptManager _runManager;
    private readonly string _systemDir = Path.Combine(Program.RepoRoot, "scripts", "_system");

    public Initializer(RunScriptManager runManager)
    {
        _runManager = runManager;
    }

    public Host Run(Action<string> onLine)
    {
        var state = _runManager.StateKeeper;
        var config = AppConfig.Load(Program.RepoRoot);

        // create NetWorkModels folder in Models folder
        // all new models execpt executor models are moving to Models/NetWorkModels
        var host = new Host();
        state.SetCurrentHost(host);
        
        // need to check inf natsdwitch and nat net exist and get existing one.
        // config is for new net only .
        // before GetHostNatSwitch - need to add step to check if exists. 
        // so no need to check in _system scripts anymore - all checks will be here - in C#
       
        host.NatNet = new Net { Alias = GetHostNatSwitch() }; // host.NexExecutor.GetHostNatSwitch()
        // all methods which work with _system scripts - are going to NexEcecutor or PythonServer.Python 
        // it depends on who performs the action

        host.SwitchName = config.Network.SwitchName; 
        host.NatNetInterface = new NetInterface { IP = GetHostNatIp() }; //host.NexExecutor.GetHostNatIP()

        // host.PythonServer.Python.GetProxyAlive();
        host.PythonServer.Alive = GetProxyAlive();

        // add method(and script to method) to get all vm on machine
        // since we dont verify existing in scripts anymore - check should be here

        // add foreach for all vmNames on host
        // 
        var actualVmNamess = host.NetExecutor.GetVMNames();
        foreach(var vmName in actualVmNamess)
        {
            var vm = new VM { Name = vmName };
            host.VMs.Add(vm);
        }

        // in future we planning to choose the name of VM we want to work with
        var currentVmName = config.Vm.Name;
        var currentVm = host.VMs.First(vm => vm.Name == currentVmName);
        state.SetCurrentVm(currentVm);


        var currentVmInfo = GetVmInfo(); // vm.NetExecutor.GetNetworkInfo() - I've changed proxyPort - to ProxyAddress in Probe mode
        // rename  VmProbe to VmFSModel (FS - from script). make a rule: data from script should come in FSModel class. except cases when data is too simple(1-2 values)
        // also move VmFSModel to a new folder FSModels-create it in root directory
        
        currentVm.Running = currentVmInfo.Running;

        // it seems like NetInterface become more complicated - now it has 3 fields. 
        // so create a differnt request like vm.NetExecutor.GetNetInterfaceInfo() which would return NetInterfaceFSModel with 3 fields accoriding to NetInterface
        currentVm.NatNetInterface = new NetInterface { Alias = currentVmInfo.InterfaceAlias, IP = currentVmInfo.NatIp };
        
        // i renamed proxyPort to ProxyAddress
        currentVm.ProxyAddress = currentVmInfo.ProxyAddress;

        // this part definitely should be written from zero
        // we have new mechanism
        // host.PythonServer.Python.GetAllConnections() - i think we have this method.
        // after that we can easyli find in that connections if we have a forwatd connection for our machine by ip
        // and we will see the forward port
        // if there is no such connection - we leave port as empty and add nothing to FwdIpdsAndPorts
        // actually, the dcitionary FwdIpdsAndPorts should be inside PythonSerer model not in Host model - move 
        var raw = GetHostVmForwardPort();
        if (!string.IsNullOrEmpty(currentVm.NatNetInterface?.IP) && int.TryParse(raw, out var port))
            host.FwdIpdsAndPorts[currentVm.NatNetInterface.IP] = port;




        Print(state, onLine);
        return host;
    }


    private string GetHostNatSwitch() => Execute("10-Get-NatSwitch.ps1").Trim();

    private string GetHostNatIp() => Execute("15-Get-HostIp.ps1").Trim();

    private string GetHostVmForwardPort() => Execute("40-Get-HostVMForwardPort.ps1").Trim();

    private bool GetProxyAlive()
    {
        var output = Execute("50-Get-ProxyStatus.ps1").Trim();
        var parts = output.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        return parts.Length > 0 && parts[0] == "true";
    }

    private VmProbe GetVmInfo()
    {
        var output = Execute("30-Get-VmInfo.ps1");
        return JsonSerializer.Deserialize<VmProbe>(output, JsonOptions) ?? new VmProbe();
    }

    private string Execute(string scriptFile)
    {
        var scriptPath = Path.Combine(_systemDir, scriptFile);
        var result = _runManager.ExecuteFileScript(scriptPath, _ => { });
        return result.Output;
    }

    private static void Print(StateKeeper state, Action<string> onLine)
    {
        var host = state.CurrentHost!;
        onLine($"[INIT] switch: {host.SwitchName}  nat: {(string.IsNullOrEmpty(host.NatNet?.Alias) ? "<none>" : host.NatNet.Alias)}  ip: {host.NatNetInterface?.IP}");
        onLine($"[INIT] VMs ({host.VMs.Count}):");

        var vm = state.CurrentVm!;
        onLine($"[INIT] {vm.Name}  running={vm.Running}  ip={vm.NatNetInterface?.IP}  alias={vm.NatNetInterface?.Alias}  proxy={vm.ProxyAddress}");
    }

    private sealed class VmProbe
    {
        public bool Running { get; set; }
        public string NatIp { get; set; } = "";
        public string InterfaceAlias { get; set; } = "";
        public string ProxyAddress { get; set; } = "";
    }
}
