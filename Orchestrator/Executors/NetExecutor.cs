using System.Text.Json;
using Orchestrator.Core;
using Orchestrator.FSModels;
using Orchestrator.Models.NetWorkModels;

namespace Orchestrator.Executors;

public class NetExecutor
{
    private readonly string Target ;
    private static readonly JsonSerializerOptions JsonOptions = new() { PropertyNameCaseInsensitive = true };

    internal RunScriptManager? RunManager;

    public NetExecutor(string target)
    {
        Target = target;
    }

    public List<string> GetNatNames()
    {
        var output = Run("GetNatNames.ps1");
        return JsonSerializer.Deserialize<List<string>>(output, JsonOptions) ?? new List<string>();
    }

    public bool NatExists(string name)
    {
        return GetNatNames().Contains(name);
    }

    public string GetHostNatSwitch()
    {
        return Run("GetHostNatSwitch.ps1").Trim();
    }

    public string GetSwitchName()
    {
        return Run("GetSwitchName.ps1").Trim();
    }

    public NetInterfaceFSModel GetHostNatInterfaceInfo()
    {
        var output = Run("GetHostNatInterfaceInfo.ps1");
        return JsonSerializer.Deserialize<NetInterfaceFSModel>(output, JsonOptions) ?? new NetInterfaceFSModel();
    }

    public VmFSModel GetNetworkInfo()
    {
        var output = Run("GetNetworkInfo.ps1");
        if (!output.TrimStart().StartsWith('{'))
            return new VmFSModel();
        return JsonSerializer.Deserialize<VmFSModel>(output, JsonOptions) ?? new VmFSModel();
    }

    public NetInterfaceFSModel GetNetInterfaceInfo()
    {
        var output = Run("GetNetInterfaceInfo.ps1");
        if (!output.TrimStart().StartsWith('{'))
            return new NetInterfaceFSModel();
        return JsonSerializer.Deserialize<NetInterfaceFSModel>(output, JsonOptions) ?? new NetInterfaceFSModel();
    }

    public Net CreateNatNet(string name)
    {
        //script
        return null;
    }

    public bool IsIpFree(string ip)
    {
        //script
        return true;
    }

    public NetInterface SetStaticIp(string alias)
    {
        string ip = "";
        while (!IsIpFree(ip))
        {
        }

        //script
        return null;
    }

    public void SetProxy(string proxyAddress)
    {
        //script
    }

    public void EnableRdp()
    {
        //script
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
        //script
        return null;
    }

    private string Run(string scriptFile)
    {
        RunManager.StateKeeper.ExecutorTarget = Target;
        var path = Path.Combine(Program.RepoRoot, "scripts", "_system", "NetExecutor", scriptFile);
        return RunManager!.ExecuteFileScript(path, _ => { }).Output;
    }
}
