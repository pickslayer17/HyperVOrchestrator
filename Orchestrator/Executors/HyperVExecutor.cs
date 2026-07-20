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

    public bool IsVMRunning(string vmName)
    {
        var output = Run("IsVMRunning.ps1", new Dictionary<string, string> { ["VmName"] = vmName });
        return output.Trim().Equals("true", StringComparison.OrdinalIgnoreCase);
    }

    public void RemoveMachine(string vmName, string vmDir)
    {
        Run("RemoveMachine.ps1", new Dictionary<string, string>
        {
            ["VmName"] = vmName,
            ["VmDir"] = vmDir,
        });
    }

    private string Run(string scriptFile, IReadOnlyDictionary<string, string>? args = null)
    {
        return RunScript("HyperVExecutor", scriptFile, args);
    }
}
