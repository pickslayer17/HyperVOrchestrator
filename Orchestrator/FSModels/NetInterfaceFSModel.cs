namespace Orchestrator.FSModels;

public sealed class NetInterfaceFSModel
{
    public bool IsDynamic { get; set; }
    public string Alias { get; set; } = "";
    public string IP { get; set; } = "";
    public int PrefixLength { get; set; }
    public string Gateway { get; set; } = "";
    public List<string> DnsServers { get; set; } = new();
}
