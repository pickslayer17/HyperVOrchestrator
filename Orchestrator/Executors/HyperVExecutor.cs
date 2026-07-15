using System.Text.Json;
using Orchestrator.Core;

namespace Orchestrator.Executors;

public class HyperVExecutor : BaseExecutor
{
    private static readonly JsonSerializerOptions JsonOptions = new() { PropertyNameCaseInsensitive = true };

    public HyperVExecutor() : base(ExecutorTarget.Host)
    {
    }

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
        return RunScript("HyperVExecutor", scriptFile);
    }
}
