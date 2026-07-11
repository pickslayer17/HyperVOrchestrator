using System.Text.Json;
using Orchestrator.Core;

namespace Orchestrator.Executors;

public class HyperVExecutor
{
    private static readonly JsonSerializerOptions JsonOptions = new() { PropertyNameCaseInsensitive = true };

    internal RunScriptManager? RunManager;

    public bool IsHyperVExists()
    {
        var output = Run("IsHyperVExists.ps1");
        return output.Trim().Equals("true", StringComparison.OrdinalIgnoreCase);
    }

    public List<string> GetVMNames()
    {
        var output = Run("GetVMNames.ps1");
        return JsonSerializer.Deserialize<List<string>>(output, JsonOptions) ?? new List<string>();
    }

    private string Run(string scriptFile)
    {
        var path = Path.Combine(Program.RepoRoot, "scripts", "_system", "HyperVExecutor", scriptFile);
        return RunManager!.ExecuteFileScript(path, _ => { }).Output;
    }
}
