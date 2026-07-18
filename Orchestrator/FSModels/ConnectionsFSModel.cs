namespace Orchestrator.FSModels;

public sealed class ConnectionsFSModel
{
    public List<string> Proxy { get; set; } = new();
    public List<DnsConnectionFSModel> Dns { get; set; } = new();
    public int Active { get; set; }
}

public sealed class DnsConnectionFSModel
{
    public string Listen { get; set; } = "";
    public string Target { get; set; } = "";
}
