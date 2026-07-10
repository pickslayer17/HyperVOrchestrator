namespace Orchestrator.FSModels;

public sealed class VmFSModel
{
    public bool Running { get; set; }
    public string NatIp { get; set; } = "";
    public string InterfaceAlias { get; set; } = "";
    public string ProxyAddress { get; set; } = "";
}
