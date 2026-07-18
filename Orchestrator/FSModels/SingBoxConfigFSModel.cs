namespace Orchestrator.FSModels;

public sealed class SingBoxConfigFSModel
{
    public string ProxyAddress { get; set; } = "";
    public string DnsAddress { get; set; } = "";
    public bool Running { get; set; }
}
