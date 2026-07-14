using Orchestrator.Config;
using Orchestrator.Core;
using Orchestrator.Executors;
using Orchestrator.Models;
using Orchestrator.Models.NetWorkModels;

namespace Orchestrator.App;

internal sealed class Orchestrator
{
    private const int CheckRunMain = 0;
    private const int CheckAlreadyDone = 2;

    private readonly AppConfig _config;
    private readonly RunScriptManager _runManager;
    private readonly ScriptModel _setupVmModel;
    private readonly ScriptModel _installSoftModel;
    private readonly ConsoleModelViewer _viewer;
    private readonly Logger _logger;
    private readonly Step? _firstStep;
    private ScriptModel _activeModel;

    private Host _host => _runManager.StateKeeper.CurrentHost!;

    public Orchestrator(AppConfig config, string scriptsRoot)
    {
        _config = config;
        _runManager = new RunScriptManager(config, scriptsRoot);
        var factory = new ScriptModelFactory();
        _setupVmModel = factory.Create(Path.Combine(scriptsRoot, "SetupVM"));
        _installSoftModel = factory.Create(Path.Combine(scriptsRoot, "InstallSoft"));
        _firstStep = FindFirstStep(_setupVmModel.Root);
        _activeModel = _setupVmModel;
        _viewer = new ConsoleModelViewer(this);
        _logger = new Logger();
    }

    public void Start()
    {
        while (true)
        {
            if (!SelectHost())
                return;
            VmLoop();
        }
    }

    private bool SelectHost()
    {
        _viewer.SetHeader(new[] { "Select host" });
        var items = new List<string> { _config.Vm.Host, "0. Exit" };
        var choice = _viewer.ShowMenu(items);
        if (choice == items.Count - 1)
        {
            Console.CursorVisible = true;
            Environment.Exit(0);
        }

        var initializer = new Initializer(_runManager);
        initializer.LoadHost();
        RefreshHeader();
        return true;
    }

    private void VmLoop()
    {
        while (true)
        {
            _viewer.SetHeader(new[] { "Select VM" });
            var items = new List<string>();
            for (var i = 0; i < _host.VMs.Count; i++)
                items.Add($"{i + 1}. {_host.VMs[i].Name}");
            items.Add($"{_host.VMs.Count + 1}. Create new VM");
            items.Add("0. Back");

            var choice = _viewer.ShowMenu(items);
            if (choice == items.Count - 1)
                return;

            VM vm;
            if (choice == items.Count - 2)
            {
                var name = ReadVmName();
                if (string.IsNullOrWhiteSpace(name))
                    continue;
                vm = new VM { Name = name };
                vm.NetExecutor = new NetExecutor("VM") { RunManager = _runManager };
            }
            else
            {
                vm = _host.VMs[choice];
            }

            var initializer = new Initializer(_runManager);
            initializer.LoadVmInfo(vm);
            RefreshHeader();
            VmActionsLoop(vm);
        }
    }

    private string ReadVmName()
    {
        _viewer.SetHeader(new[] { "Create new VM" });
        Console.Clear();
        Console.CursorVisible = true;
        Console.Write("  VM name (empty = cancel): ");
        var name = Console.ReadLine()?.Trim() ?? "";
        Console.CursorVisible = false;
        return name;
    }

    private void VmActionsLoop(VM vm)
    {
        var items = new List<string>
        {
            "1. Setup VM",
            "2. Setup Network",
            "3. Install Soft",
            "4. Full Setup",
            "0. Back",
        };
        while (true)
        {
            var choice = _viewer.ShowMenu(items);
            if (choice == 0)
                RunModel(_setupVmModel);
            else if (choice == 1)
                NetworkStepsLoop(vm);
            else if (choice == 2)
                RunModel(_installSoftModel);
            else if (choice == 3)
                FullSetup(vm);
            else
                return;
        }
    }

    private void RunModel(ScriptModel model)
    {
        _activeModel = model;
        _viewer.ShowTree(model);
    }

    private void NetworkStepsLoop(VM vm)
    {
        var networkSetup = new NetworkSetup(_runManager.StateKeeper);
        var steps = networkSetup.GetSteps();
        var items = new List<string>();
        for (var i = 0; i < steps.Count; i++)
            items.Add($"{i + 1}. {steps[i].Name}");
        items.Add("0. Back");

        while (true)
        {
            var choice = _viewer.ShowMenu(items);
            if (choice == items.Count - 1)
                return;
            RunNetworkStep(steps[choice].Name, steps[choice].Run);
        }
    }

    private bool RunNetworkStep(string name, Action action)
    {
        _viewer.BeginRun();
        _logger.SetContext("network/" + name);
        WriteLine($"[NETWORK {name}]");
        try
        {
            action();
            WriteLine($"[NETWORK {name}: done]");
            RefreshHeader();
            _viewer.ResumeAfterRun();
            return true;
        }
        catch (Exception exception)
        {
            WriteLine($"[NETWORK {name}: failed — {exception.Message}]");
            RefreshHeader();
            _viewer.ResumeAfterRun();
            return false;
        }
    }

    private void FullSetup(VM vm)
    {
        _viewer.BeginRun();
        _activeModel = _setupVmModel;
        if (!RunSuite(_setupVmModel.Root))
        {
            FinishFullSetup("Setup VM failed");
            return;
        }
        _setupVmModel.Root.Recalculate();

        var networkSetup = new NetworkSetup(_runManager.StateKeeper);
        try
        {
            networkSetup.Configure();
        }
        catch (Exception exception)
        {
            FinishFullSetup($"Setup Network failed — {exception.Message}");
            return;
        }
        RefreshHeader();

        _activeModel = _installSoftModel;
        if (!RunSuite(_installSoftModel.Root))
        {
            FinishFullSetup("Install Soft failed");
            return;
        }
        _installSoftModel.Root.Recalculate();

        FinishFullSetup("Full setup done");
    }

    private void FinishFullSetup(string message)
    {
        WriteLine($"[FULL SETUP: {message}]");
        _viewer.ResumeAfterRun();
    }

    private void RefreshHeader()
    {
        var state = _runManager.StateKeeper;
        var host = state.CurrentHost;
        var server = host?.PythonServer;
        var vm = state.CurrentVm;
        _viewer.SetHeader(new[]
        {
            host is null ? "Host:" : $"Host:  switch={host.SwitchName}  nat={host.NatNet?.Alias}  ip={host.NatNetInterface?.IP}",
            server is null ? "Python server:" : $"Python server:  {(server.Alive ? "up" : "down")}",
            vm is null ? "VM:" : $"VM:  {vm.Name}  running={vm.Running}  ip={vm.NatNetInterface?.IP}  alias={vm.NatNetInterface?.Alias}  proxy={vm.ProxyAddress}",
        });
    }

    private bool ConfirmFirstStep(Step step)
    {
        var confirmed = _viewer.ConfirmInHeader($"Run {step}?  This wipes the VM.  (y = confirm, any other = cancel)");
        if (!confirmed)
            WriteLine($"[{step}] cancelled");
        return confirmed;
    }

    private static Step? FindFirstStep(Suite suite)
    {
        if (suite.Steps.Count > 0)
            return suite.Steps[0];
        foreach (var childSuite in suite.ChildSuites)
        {
            var found = FindFirstStep(childSuite);
            if (found is not null)
                return found;
        }
        return null;
    }

    public void Run(IScriptNode node)
    {
        if (node is Step step)
            RunStep(step);
        else if (node is Suite suite)
            RunSuite(suite);

        _activeModel.Root.Recalculate();
        _viewer.ResumeAfterRun();
    }

    private bool RunSuite(Suite suite)
    {
        foreach (var step in suite.Steps)
        {
            if (!RunStep(step))
                return false;
        }
        foreach (var childSuite in suite.ChildSuites)
        {
            if (!RunSuite(childSuite))
                return false;
        }
        return true;
    }

    private bool RunStep(Step step)
    {
        if (ReferenceEquals(step, _firstStep) && !ConfirmFirstStep(step))
            return false;

        if (!step.HasCheck)
        {
            var okNoCheck = RunMain(step);
            if (okNoCheck) step.State = StepState.NoCheck;
            return okNoCheck;
        }

        _logger.SetContext(step + "/check");
        WriteLine($"[CHECK {step}]");
        var checkResult = _runManager.ExecuteFileScript(step.CheckPath, WriteLine);
        RefreshHeader();
        if (checkResult.ExitCode == CheckAlreadyDone)
        {
            WriteLine($"[CHECK RESULT: already done — skipping main]");
            step.State = StepState.AlreadyDone;
            return true;
        }
        if (checkResult.ExitCode != CheckRunMain)
        {
            WriteLine($"[CHECK RESULT: failed (exit {checkResult.ExitCode}) — main not run]");
            step.State = StepState.Failed;
            return false;
        }

        WriteLine($"[CHECK RESULT: needs work — running main]");
        var ok = RunMain(step);
        return ok;
    }

    private bool RunMain(Step step)
    {
        _logger.SetContext(step + "/main");
        WriteLine($"[STEP {step}]");
        var result = _runManager.ExecuteFileScript(step.ScriptPath, WriteLine);
        RefreshHeader();
        if (result.ExitCode == 0)
        {
            step.State = StepState.Passed;
            return true;
        }
        step.State = StepState.Failed;
        return false;
    }

    private void WriteLine(string line)
    {
        _logger.Write(line);
        _viewer.WriteOutput(line);
    }
}
