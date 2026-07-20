using Orchestrator.Config;
using Orchestrator.Core;
using Orchestrator.Enums;
using Orchestrator.Executors;
using Orchestrator.FSModels;
using Orchestrator.Models.Azure;
using Orchestrator.Models.NetWorkModels;
using System.Net;

namespace Orchestrator.App;

internal sealed class Initializer
{
    private readonly RunScriptManager _runManager;

    public Initializer(RunScriptManager runManager)
    {
        _runManager = runManager;
    }

    public void LoadAgentPool()
    {
        var config = AppConfig.Load(Program.RepoRoot);
        _runManager.StateKeeper.AgentPool = new AgentPool { Name = config.Agent.Pool };
    }

    public Host LoadHost()
    {
        var state = _runManager.StateKeeper;
        var config = AppConfig.Load(Program.RepoRoot);

        var host = new Host();
        state.SetCurrentHost(host);
        host.NetExecutor = new NetExecutor(ExecutorTarget.Host) { RunManager = _runManager };
        host.HyperVExecutor = new HyperVExecutor { RunManager = _runManager };
        host.PythonServer.PythonExecutor = new PythonExecutor { RunManager = _runManager };

        var globalInterface = host.NetExecutor.GetHostGlobalInterfaceInfo();
        host.GlobalNetInterface = new NetInterface
        {
            IsDynamic = globalInterface.IsDynamic,
            Alias = globalInterface.Alias,
            IP = globalInterface.IP,
        };

        if (host.NetExecutor.NatExists(config.Network.NatName))
        {
            host.NatNet = new Net { Alias = host.NetExecutor.GetHostNatSwitch() };
            host.SwitchName = host.NetExecutor.GetSwitchName();

            var hostInterface = host.NetExecutor.GetHostNatInterfaceInfo(config.Network.SwitchName);
            host.NatNetInterface = new NetInterface
            {
                IsDynamic = hostInterface.IsDynamic,
                Alias = hostInterface.Alias,
                IP = hostInterface.IP,
            };
        }

        LoadPythonServer(host.PythonServer);

        if (!host.HyperVExecutor.IsHyperVExists())
            return host;

        var actualVmNames = host.HyperVExecutor.GetVMNames();
        foreach (var vmName in actualVmNames)
        {
            var vm = new VM { Name = vmName };
            vm.NetExecutor = new NetExecutor(ExecutorTarget.VM) { RunManager = _runManager };
            vm.SingBoxExecutor = new SingBoxExecutor { RunManager = _runManager };
            host.VMs.Add(vm);
        }

        return host;
    }

    public void LoadVmInfo(VM vm)
    {
        var state = _runManager.StateKeeper;
        var host = state.CurrentHost!;
        state.SetCurrentVm(vm);
        LoadPythonServer(host.PythonServer);

        if (Enum.TryParse<OfficeApp>(vm.Name, ignoreCase: true, out var officeApp))
            vm.OfficeApp = officeApp;

        vm.Running = host.HyperVExecutor.IsVMRunning(vm.Name);
        if (!vm.Running)
        {
            vm.NatNetInterface = new NetInterface();
            vm.ProxyAddress = null;
            vm.DnsAddress = null;
            vm.SingBoxRunning = false;
            return;
        }

        var networkInfo = vm.NetExecutor.GetNetworkInfo();
        vm.NatNetInterface = new NetInterface
        {
            Alias = networkInfo.InterfaceAlias,
            IP = networkInfo.NatIp,
        };
        LoadSingBox(vm);
    }

    private static void LoadPythonServer(PythonServer server)
    {
        server.Alive = server.PythonExecutor.IsAlive();
        var connections = server.Alive ? server.PythonExecutor.GetAllConnections() : new ConnectionsFSModel();
        server.ActiveConnections = connections.Active;
        server.ProxyConnections = connections.Proxy.Select(ParseEndpoint).ToList();
        server.DnsConnections = connections.Dns.ToDictionary(
            connection => ParseEndpoint(connection.Listen),
            connection => ParseEndpoint(connection.Target));
    }

    private static void LoadSingBox(VM vm)
    {
        var config = vm.SingBoxExecutor.GetConfig();
        vm.ProxyAddress = ParseOptionalEndpoint(config.ProxyAddress);
        vm.DnsAddress = ParseOptionalEndpoint(config.DnsAddress);
        vm.SingBoxRunning = config.Running;
    }

    private static IPEndPoint? ParseOptionalEndpoint(string value)
    {
        return string.IsNullOrWhiteSpace(value) ? null : ParseEndpoint(value);
    }

    private static IPEndPoint ParseEndpoint(string value)
    {
        if (!IPEndPoint.TryParse(value, out var endpoint))
            throw new InvalidOperationException($"Invalid endpoint '{value}'.");
        return endpoint;
    }
}
