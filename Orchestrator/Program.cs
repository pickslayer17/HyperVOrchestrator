using Orchestrator.App;
using Orchestrator.Config;

namespace Orchestrator;

internal static class Program
{
    public readonly static string RepoRoot = FindRepoRoot();
    private const string RepoRootMarker = "default.config.json";
    private const string ScriptsFolder = "scripts";

    private static void Main()
    {
        var scriptsRoot = Path.Combine(RepoRoot, ScriptsFolder);
        var config = AppConfig.Load(RepoRoot);

        var orchestrator = new App.Orchestrator(config, scriptsRoot);
        orchestrator.Start();
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
