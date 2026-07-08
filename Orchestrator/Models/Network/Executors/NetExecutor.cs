using ConsoleApp1.NetworkModel;
using System.Net;

namespace ConsoleApp1.Executors;

// all non-specific stuff
public class NetExecutor
{
    public List<string> GetNatNames()
    {
        //script;
        //return from_script;
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
        //return from_script;
        return true;
    }

    public void SetStaticIp(string netName)
    {
        // create some IP -> var ip;
        string ip = "";
        while (!IsIpFree(ip))
        {
            //some logic to get ips until its not free
        }

       //script;
    }

    public int GetFreePort(string netName)
    {
        //script
        return 0;
    }

    public Net GetNetInfo(string natName)
    {
        //script; fill 
        return null;
    }

    public NetInterface GetHostNetInterfaceInfo(string natName)
    {
        //script;
        return null;
    }
}
