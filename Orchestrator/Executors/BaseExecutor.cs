using Orchestrator.Core;

namespace Orchestrator.Executors;

public enum ExecutorTarget
{
    Host,
    VM,
}

public abstract class BaseExecutor
{
    protected readonly ExecutorTarget Target;

    internal RunScriptManager? RunManager;

    protected BaseExecutor(ExecutorTarget target)
    {
        Target = target;
    }

    private protected string RunScript(string executorName, string scriptFile, IReadOnlyDictionary<string, string>? args = null)
    {
        RunManager!.Target = Target;
        var path = Path.Combine(Program.RepoRoot, "scripts", "_system", executorName, scriptFile);
        var result = RunManager.ExecuteFileScript(path, _ => { }, args);
        if (result.ExitCode != 0)
        {
            var details = string.IsNullOrWhiteSpace(result.Output) ? "" : $": {result.Output.Trim()}";
            throw new InvalidOperationException($"{executorName}/{scriptFile} failed with exit code {result.ExitCode}{details}");
        }
        return result.Output;
    }
}
