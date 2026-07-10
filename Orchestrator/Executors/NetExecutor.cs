using Orchestrator.Models;

namespace Orchestrator.Executors;

public class NetExecutor
{
    public List<string> GetNatNames()
    {
        //script;
        return null;
    }

    public bool NatExists(string name)
    {
        var natNames = GetNatNames();
        if (natNames.Count > 0 && natNames.Contains(name))
            return true;

        return false;
    }

    public Net CreateNatNet(string name)
    {
        // script
        return null;
    }

    public bool IsIpFree(string ip)
    {
        //script;
        return true;
    }

    public NetInterface SetStaticIp(string alias)
    {
        string ip = "";
        while (!IsIpFree(ip))
        {
        }

        //script;
        return null;
    }

    public void SetProxy(string proxyAddress)
    {
        //script;
    }

    public void EnableRdp()
    {
        //script;
    }

    public int GetFreePort(string netName)
    {
        //script
        return 0;
    }

    public Net GetNetInfo(string natName)
    {
        //script
        return null;
    }

    public NetInterface GetHostNetInterfaceInfo(string natName)
    {
        //script;
        return null;
    }
}
