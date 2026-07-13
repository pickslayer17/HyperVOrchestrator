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

    public Net CreateNatNet(string name, string switchName, string hostIp, int prefixLength)
    {
        Run("CreateNatNet.ps1", new Dictionary<string, string>
        {
            ["NatName"] = name,
            ["SwitchName"] = switchName,
            ["HostIp"] = hostIp,
            ["PrefixLength"] = prefixLength.ToString(),
        });
        return GetNetInfo(name);
    }

    public bool IsIpFree(string ip)
    {
        var output = Run("IsIpFree.ps1", new Dictionary<string, string> { ["Ip"] = ip });
        return output.Trim().Equals("true", StringComparison.OrdinalIgnoreCase);
    }

    public NetInterface SetStaticIp(string alias, string ip, string gateway, int prefixLength, string dns)
    {
        Run("SetStaticIp.ps1", new Dictionary<string, string>
        {
            ["Alias"] = alias,
            ["Ip"] = ip,
            ["Gateway"] = gateway,
            ["PrefixLength"] = prefixLength.ToString(),
            ["Dns"] = dns,
        });
        return new NetInterface { IsDynamic = false, Alias = alias, IP = ip };
    }

    public void SetProxy(string proxyAddress)
    {
        Run("SetProxy.ps1", new Dictionary<string, string> { ["ProxyAddress"] = proxyAddress });
    }

    public void EnableRdp()
    {
        Run("EnableRdp.ps1");
    }

    public int GetFreePort(string netName)
    {
        var output = Run("GetFreePort.ps1");
        return int.Parse(output.Trim());
    }

    public Net GetNetInfo(string natName)
    {
        var output = Run("GetNetInfo.ps1", new Dictionary<string, string> { ["NatName"] = natName });
        var model = JsonSerializer.Deserialize<NetFSModel>(output, JsonOptions) ?? new NetFSModel();
        return new Net
        {
            Alias = model.Alias,
            HostNetInterface = ToNetInterface(model.HostNetInterface),
            NetInterfaces = model.NetInterfaces.Select(ToNetInterface).ToList(),
        };
    }

    public NetInterface GetHostNetInterfaceInfo(string natName)
    {
        var output = Run("GetHostNetInterfaceInfo.ps1", new Dictionary<string, string> { ["NatName"] = natName });
        var model = JsonSerializer.Deserialize<NetInterfaceFSModel>(output, JsonOptions) ?? new NetInterfaceFSModel();
        return ToNetInterface(model);
    }

    private static NetInterface ToNetInterface(NetInterfaceFSModel model)
    {
        return new NetInterface { IsDynamic = model.IsDynamic, Alias = model.Alias, IP = model.IP };
    }

    private string Run(string scriptFile, IReadOnlyDictionary<string, string>? args = null)
    {
        RunManager.StateKeeper.ExecutorTarget = Target;
        var path = Path.Combine(Program.RepoRoot, "scripts", "_system", "NetExecutor", scriptFile);
        return RunManager!.ExecuteFileScript(path, _ => { }, args).Output;
    }
}
