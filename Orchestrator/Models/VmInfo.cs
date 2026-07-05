namespace Orchestrator.Models;

internal sealed class VmInfo
{
    public string Name { get; set; } = "";
    public bool Running { get; set; }
    public string natName { get; set; } = "";
    public string Ip { get; set; } = "";
    public string ProxyPort { get; set; } = "";
    public string RdpPort { get; set; } = "";
    public string HostRdpForwardPort { get; set; } = "";
    public string InterfaceAlias { get; set; } = "";
}
