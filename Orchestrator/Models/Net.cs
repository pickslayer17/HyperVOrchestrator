namespace Orchestrator.Models;

public class Net
{
    public string Alias;
    public NetInterface HostNetInterface;
    public List<NetInterface> NetInterfaces = new();
}
