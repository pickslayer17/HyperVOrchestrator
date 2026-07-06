using System.Text.Json;
using Orchestrator.Config;
using Orchestrator.Core;
using Orchestrator.Models;

namespace Orchestrator.App;

internal sealed class Initializer
{
    private static readonly JsonSerializerOptions JsonOpts =
        new() { PropertyNameCaseInsensitive = true };

    private readonly RunScriptManager _runManager;
    private readonly string _systemDir = Path.Combine(Program.RepoRoot, "scripts", "_system");

    public Initializer(RunScriptManager runManager)
    {
        _runManager = runManager;
    }

    public HostInfo Run(Action<string> onLine)
    {
        var state = _runManager.StateKeeper;
        var config = AppConfig.Load(Program.RepoRoot);
        var host = new HostInfo();
        state.AddHost(host);
        state.SetCurrentHost(host);
        host.HyperV = GetHostHyperV();
        host.SwitchName = config.Network.SwitchName;
        host.NatName = GetHostNatSwitch();

        var vm = new VmInfo{ Name = config.Vm.Name };
        host.Vms[vm.Name] = vm;
        state.SetCurrentVm(vm.Name);
        var vmInfo = GetVmInfo();
        vm.HostRdpForwardPort = vmInfo.HostRdpForwardPort;
        vm.InterfaceAlias = vmInfo.InterfaceAlias;
        vm.Ip = vmInfo.Ip;
        vm.natName = vmInfo.natName;
        vm.ProxyPort = vmInfo.ProxyPort;
        vm.RdpPort = vmInfo.RdpPort;
        vm.Running = vmInfo.Running;

        Print(state, onLine);
        return host;
    }

    private bool GetHostHyperV()
    {
        var output = Execute("00-Get-HyperV.ps1");
        return output.Trim().Equals("true", StringComparison.OrdinalIgnoreCase);
    }

    private string GetHostNatSwitch()
    {
        var output = Execute("10-Get-NatSwitch.ps1");
        return output.Trim();
    }

    private List<string> GetHostVmNames()
    {
        var output = Execute("20-Get-VmNames.ps1");
        var names = JsonSerializer.Deserialize<List<string>>(output, JsonOpts);
        return names ?? new List<string>();
    }

    private VmInfo GetVmInfo()
    {
        var output = Execute("30-Get-VmInfo.ps1");
        var vm = JsonSerializer.Deserialize<VmInfo>(output, JsonOpts);
        return vm;
    }

    private string Execute(string scriptFile)
    {
        var path = Path.Combine(_systemDir, scriptFile);
        var result = _runManager.ExecuteFileScript(path, _ => { });
        return result.Output;
    }

    private static void Print(StateKeeper stateKeeper, Action<string> onLine)
    {
        var host = stateKeeper.CurrentHost;
        onLine($"[INIT] Hyper-V: {host.HyperV}  NAT switch: {(string.IsNullOrEmpty(host.NatName) ? "<none>" : host.NatName)}");
        onLine($"[INIT] VMs ({host.Vms.Count}):");

        var vm = stateKeeper.CurrentVm;
        onLine($"[INIT] {vm.Name}  running={vm.Running}  ip={vm.Ip} rdp={vm.RdpPort} proxy={vm.ProxyPort} alias={vm.InterfaceAlias}");
    }
}
