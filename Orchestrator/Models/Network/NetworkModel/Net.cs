namespace ConsoleApp1.NetworkModel;

public class Net
{
    public string Name;
    public NetInterface HostNetInterface;
    public List<NetInterface> NetInterfaces = new();

    public Net()
    {
    }
}
