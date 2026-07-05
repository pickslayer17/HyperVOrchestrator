using Orchestrator.App;
using Orchestrator.Config;
using Orchestrator.Core;

namespace Orchestrator;

internal static class Program
{
    public readonly static string RepoRoot = FindRepoRoot();
    private const string RepoRootMarker = "default.config.json";
    private const string ScriptsFolder = "scripts";
    private const string VmSuitesFolder = "VM";

    private static int Main(string[] arguments)
    {
        var scriptsRoot = Path.Combine(RepoRoot, ScriptsFolder);
        var vmSuitesDir = Path.Combine(scriptsRoot, VmSuitesFolder);
        var config = AppConfig.Load(RepoRoot);

        if (arguments.Length > 0)
        {
            var exitCode = RunHeadless(config, scriptsRoot, arguments[0]);
            return exitCode;
        }

        var orchestrator = new App.Orchestrator(config, scriptsRoot, vmSuitesDir);
        orchestrator.Start();
        return 0;
    }

    private static int RunHeadless(AppConfig config, string scriptsRoot, string scriptPath)
    {
        var runManager = new RunScriptManager(config, scriptsRoot);
        var result = runManager.ExecuteFileScript(scriptPath, Console.WriteLine);
        return result.ExitCode;
    }

    private static string FindRepoRoot()
    {
        var directory = new DirectoryInfo(AppContext.BaseDirectory);
        while (directory is not null)
        {
            if (File.Exists(Path.Combine(directory.FullName, RepoRootMarker)))
                return directory.FullName;
            directory = directory.Parent;
        }
        throw new InvalidOperationException($"Repo root not found (no '{RepoRootMarker}' above the exe).");
    }
}
