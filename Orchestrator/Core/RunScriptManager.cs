using Orchestrator.Config;
using Orchestrator.Helpers;
using Orchestrator.Models;

namespace Orchestrator.Core;

internal sealed class RunScriptManager
{
    private readonly PreScriptProcessor _preProcessor;
    private readonly PostScriptProcessor _postProcessor;
    private readonly ScriptRunner _scriptRunner;

    public StateKeeper StateKeeper { get; }

    public RunScriptManager(AppConfig config, string scriptsRoot)
    {
        var stateKeeper = new StateKeeper();
        StateKeeper = stateKeeper;
        var host = new PowerShellHost();
        _preProcessor = new PreScriptProcessor(scriptsRoot, config, stateKeeper, host);
        _postProcessor = new PostScriptProcessor(new ResultParser(stateKeeper));
        _scriptRunner = new ScriptRunner(host);
    }

    public Result ExecuteFileScript(string scriptPath, Action<string> onLine)
    {
        var rawScript = FileHelper.ReadText(scriptPath);
        var processedScript = _preProcessor.Process(rawScript);
        var lineHandler = _postProcessor.WrapLineHandler(onLine);
        var result = _scriptRunner.Run(processedScript, lineHandler);
        return result;
    }

    public void Cancel()
    {
        _scriptRunner.Cancel();
    }
}
