using Orchestrator.FSModels;
using Orchestrator.Models.NetWorkModels;

namespace Orchestrator.Executors;

public class NetExecutor
{
    public List<string> GetNatNames()
    {
        //script;
        return new List<string>();
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

    public string GetHostNatSwitch()
    {
        //script: 10-Get-NatSwitch.ps1
        return "";
    }

    public string GetHostNatIP()
    {
        //script: 15-Get-HostIp.ps1
        return "";
    }

    public List<string> GetVMNames()
    {
        //script: 20-Get-VmNames.ps1
        return new List<string>();
    }

    public VmFSModel GetNetworkInfo()
    {
        //script: 30-Get-VmInfo.ps1
        return new VmFSModel();
    }

    public NetInterfaceFSModel GetNetInterfaceInfo()
    {
        //script: guest net interface (3 fields)
        return new NetInterfaceFSModel();
    }
}
