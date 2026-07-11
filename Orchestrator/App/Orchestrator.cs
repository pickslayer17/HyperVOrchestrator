using Orchestrator.Config;
using Orchestrator.Core;
using Orchestrator.Models;
using Orchestrator.Models.NetWorkModels;

namespace Orchestrator.App;

internal sealed class Orchestrator
{
    private const int CheckRunMain = 0;
    private const int CheckAlreadyDone = 2;

    private readonly AppConfig _config;
    private readonly string _scriptsRoot;
    private readonly RunScriptManager _runManager;
    private readonly ScriptModel _model;
    private readonly ConsoleModelViewer _viewer;
    private readonly Logger _logger;
    private readonly Step? _firstStep;
    private Host _host = new();

    public Orchestrator(AppConfig config, string scriptsRoot, string vmSuitesDir)
    {
        _config = config;
        _scriptsRoot = scriptsRoot;
        _runManager = new RunScriptManager(config, scriptsRoot);
        var factory = new ScriptModelFactory();
        _model = factory.Create(vmSuitesDir);
        _firstStep = FindFirstStep(_model.Root);
        _viewer = new ConsoleModelViewer(this, _model);
        _logger = new Logger();
    }

    public void Start()
    {
        RunInitialization();
        RefreshHeader();
        _viewer.Draw();
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

    private void RunInitialization()
    {
        var initializer = new Initializer(_runManager);
        _host = initializer.Run();
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

        _model.Root.Recalculate();
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
