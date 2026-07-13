namespace Orchestrator.FSModels;

public sealed class NetFSModel
{
    public string Alias { get; set; } = "";
    public NetInterfaceFSModel HostNetInterface { get; set; } = new();
    public List<NetInterfaceFSModel> NetInterfaces { get; set; } = new();
}
