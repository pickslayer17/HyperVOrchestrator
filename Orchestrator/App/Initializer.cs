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

        var host = new Host();
        state.SetCurrentHost(host);
        host.SwitchName = config.Network.SwitchName;
        host.NatNet = new Net { Alias = GetHostNatSwitch() };
        host.NatNetInterface = new NetInterface { IP = GetHostNatIp() };
        host.PythonServer.Alive = GetProxyAlive();

        var vm = new VM { Name = config.Vm.Name };
        host.VMs.Add(vm);
        state.SetCurrentVm(vm);
        var probe = GetVmInfo();
        vm.Running = probe.Running;
        vm.NatNetInterface = new NetInterface { Alias = probe.InterfaceAlias, IP = probe.NatIp };
        vm.ProxyAddress = probe.ProxyPort;
        RegisterForwardPort(host, vm);

        Print(state, onLine);
        return host;
    }

    private void RegisterForwardPort(Host host, VM vm)
    {
        var raw = GetHostVmForwardPort();
        if (!string.IsNullOrEmpty(vm.NatNetInterface?.IP) && int.TryParse(raw, out var port))
            host.FwdIpdsAndPorts[vm.NatNetInterface.IP] = port;
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
        public string ProxyPort { get; set; } = "";
    }
}
