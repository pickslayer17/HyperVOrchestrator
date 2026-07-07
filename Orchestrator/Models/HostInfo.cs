namespace Orchestrator.Models;

internal sealed class HostInfo
{
    public bool HyperV { get; set; }
    public string SwitchName { get; set; } = "";
    public string NatName { get; set; } = "";
    public string NatIp { get; set; } = "";
    public string ProxyPort { get; set; } = "";
    public bool ProxyServerAlive { get; set; }
    public int ProxyVmCount { get; set; }
    public Dictionary<string, VmInfo> Vms { get; set; } = new();
}
