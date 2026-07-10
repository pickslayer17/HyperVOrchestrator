namespace Orchestrator.FSModels;

public sealed class ConnectionsFSModel
{
    public List<string> Proxy { get; set; } = new();
    public List<ForwardFSModel> Fwd { get; set; } = new();
    public int Active { get; set; }
}

public sealed class ForwardFSModel
{
    public string Listen { get; set; } = "";
    public string Target { get; set; } = "";
}
