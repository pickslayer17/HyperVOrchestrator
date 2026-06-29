using Orchestrator.Models;

namespace Orchestrator.App;

internal sealed class ScriptModelFactory
{
    private const string CheckSuffix = ".check.ps1";
    private const string ScriptSuffix = ".ps1";

    public ScriptModel Create(string scriptsDir)
    {
        var root = BuildSuite(scriptsDir, null);
        var model = new ScriptModel { Root = root };
        return model;
    }

    private Suite BuildSuite(string directory, Suite? parent)
    {
        var suite = new Suite
        {
            Name = Path.GetFileName(directory),
            Parent = parent,
        };

        var stepFiles = FindStepFiles(directory);
        foreach (var scriptPath in stepFiles)
        {
            var step = BuildStep(scriptPath, suite);
            suite.Steps.Add(step);
        }

        var subDirectories = Directory.GetDirectories(directory);
        Array.Sort(subDirectories, StringComparer.OrdinalIgnoreCase);
        foreach (var subDirectory in subDirectories)
        {
            var childSuite = BuildSuite(subDirectory, suite);
            suite.ChildSuites.Add(childSuite);
        }

        return suite;
    }

    private Step BuildStep(string scriptPath, Suite parent)
    {
        var checkPath = scriptPath[..^ScriptSuffix.Length] + CheckSuffix;
        var hasCheck = File.Exists(checkPath);

        var step = new Step
        {
            Name = Path.GetFileNameWithoutExtension(scriptPath),
            ScriptPath = scriptPath,
            CheckPath = hasCheck ? checkPath : "",
            HasCheck = hasCheck,
            Parent = parent,
        };
        return step;
    }

    private List<string> FindStepFiles(string directory)
    {
        var allScripts = Directory.GetFiles(directory, "*" + ScriptSuffix);
        Array.Sort(allScripts, StringComparer.OrdinalIgnoreCase);

        var steps = new List<string>();
        foreach (var path in allScripts)
        {
            if (path.EndsWith(CheckSuffix, StringComparison.OrdinalIgnoreCase))
                continue;
            steps.Add(path);
        }
        return steps;
    }
}
