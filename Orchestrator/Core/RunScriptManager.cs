using Orchestrator.Config;
using Orchestrator.Helpers;
using Orchestrator.Models;

namespace Orchestrator.Core;

internal sealed class RunScriptManager
{
    private readonly PreScriptProcessor _preProcessor;
    private readonly PostScriptProcessor _postProcessor;
    private readonly ScriptRunner _scriptRunner;

    public RunScriptManager(AppConfig config, string repoRoot)
    {
        var stateKeeper = new StateKeeper(config.Paths.StateFile);
        _preProcessor = new PreScriptProcessor(repoRoot, config, stateKeeper);
        _postProcessor = new PostScriptProcessor(new ResultParser(stateKeeper));
        _scriptRunner = new ScriptRunner();
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
