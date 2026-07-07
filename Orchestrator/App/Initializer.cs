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
        host.NatIp = GetHostNatIp();
        var proxyStatus = GetProxyStatus();
        host.ProxyServerAlive = proxyStatus.Alive;
        host.ProxyVmCount = proxyStatus.VmCount;

        var vm = new VmInfo{ Name = config.Vm.Name };
        host.Vms[vm.Name] = vm;
        state.SetCurrentVm(vm.Name);
        var vmInfo = GetVmInfo();
        vm.InterfaceAlias = vmInfo.InterfaceAlias;
        vm.Ip = vmInfo.Ip;
        vm.natName = vmInfo.natName;
        vm.HostProxyPort = vmInfo.HostProxyPort;
        vm.RdpInPort = vmInfo.RdpInPort;
        vm.Running = vmInfo.Running;
        vm.HostRdpForwardPort = GetHostForwardPort();

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
        var vmNames = JsonSerializer.Deserialize<List<string>>(output, JsonOptions);
        return vmNames ?? new List<string>();
    }

    private VmInfo GetVmInfo()
    {
        var output = Execute("30-Get-VmInfo.ps1");
        var vm = JsonSerializer.Deserialize<VmInfo>(output, JsonOptions);
        return vm;
    }

    private string GetHostForwardPort()
    {
        var output = Execute("40-Get-ForwardPort.ps1");
        return output.Trim();
    }

    private string GetHostNatIp()
    {
        var output = Execute("15-Get-HostIp.ps1");
        return output.Trim();
    }

    private (bool Alive, int VmCount) GetProxyStatus()
    {
        var output = Execute("50-Get-ProxyStatus.ps1").Trim();
        var parts = output.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        var alive = parts.Length > 0 && parts[0] == "true";
        var vmCount = parts.Length > 1 && int.TryParse(parts[1], out var parsed) ? parsed : 0;
        return (alive, vmCount);
    }

    private string Execute(string scriptFile)
    {
        var scriptPath = Path.Combine(_systemDir, scriptFile);
        var result = _runManager.ExecuteFileScript(scriptPath, _ => { });
        return result.Output;
    }

    private static void Print(StateKeeper stateKeeper, Action<string> onLine)
    {
        var host = stateKeeper.CurrentHost;
        onLine($"[INIT] Hyper-V: {host.HyperV}  NAT switch: {(string.IsNullOrEmpty(host.NatName) ? "<none>" : host.NatName)}");
        onLine($"[INIT] VMs ({host.Vms.Count}):");

        var vm = stateKeeper.CurrentVm;
        onLine($"[INIT] {vm.Name}  running={vm.Running}  ip={vm.Ip} rdp={vm.RdpInPort} proxy={vm.HostProxyPort} alias={vm.InterfaceAlias}");
    }
}
