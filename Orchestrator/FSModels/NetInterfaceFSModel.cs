namespace Orchestrator.FSModels;

public sealed class NetInterfaceFSModel
{
    public bool IsDynamic { get; set; }
    public string Alias { get; set; } = "";
    public string IP { get; set; } = "";
}
