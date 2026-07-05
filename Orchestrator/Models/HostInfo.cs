namespace Orchestrator.Models;

internal sealed class HostInfo
{
    public bool HyperV { get; set; }
    public string NatName { get; set; } = "";
    public Dictionary<string, VmInfo> Vms { get; set; } = new();
}
