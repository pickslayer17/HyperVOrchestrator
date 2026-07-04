using Orchestrator.App;
using Orchestrator.Config;
using Orchestrator.Core;

namespace Orchestrator;

internal static class Program
{
    private static int Main(string[] arguments)
    {
        var repoRoot = FindRepoRoot();
        var scriptsDir = Path.Combine(repoRoot, "scripts", "VM");
        var config = AppConfig.Load(repoRoot);

        if (arguments.Length > 0)
        {
            var exitCode = RunHeadless(config, repoRoot, arguments[0]);
            return exitCode;
        }

        var orchestrator = new App.Orchestrator(config, repoRoot, scriptsDir);
        orchestrator.Start();
        return 0;
    }

    private static int RunHeadless(AppConfig config, string repoRoot, string scriptPath)
    {
        var runManager = new RunScriptManager(config, repoRoot);
        var result = runManager.ExecuteFileScript(scriptPath, Console.WriteLine);
        return result.ExitCode;
    }

    private static string FindRepoRoot()
    {
        var directory = new DirectoryInfo(AppContext.BaseDirectory);
        while (directory is not null)
        {
            var scriptsPath = Path.Combine(directory.FullName, "scripts", "VM");
            if (Directory.Exists(scriptsPath))
                return directory.FullName;
            directory = directory.Parent;
        }
        throw new InvalidOperationException("Repo root not found (no 'scripts' folder above the exe).");
    }
}
