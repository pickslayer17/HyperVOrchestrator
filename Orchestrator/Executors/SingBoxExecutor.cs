using System.Text.Json;
using Orchestrator.Core;
using Orchestrator.FSModels;

namespace Orchestrator.Executors;

public sealed class SingBoxExecutor : BaseExecutor
{
    private static readonly JsonSerializerOptions JsonOptions = new() { PropertyNameCaseInsensitive = true };

    public SingBoxExecutor() : base(ExecutorTarget.VM)
    {
    }

    public void SetConfig(string hostIp, int socksPort, int dnsPort)
    {
        var templatePath = Path.Combine(Program.RepoRoot, "templates", "sing-box.template.json");
        var template = Convert.ToBase64String(File.ReadAllBytes(templatePath));
        Run("SetConfig.ps1", new Dictionary<string, string>
        {
            ["HostIp"] = hostIp,
            ["SocksPort"] = socksPort.ToString(),
            ["DnsPort"] = dnsPort.ToString(),
            ["Template"] = template,
        });
    }

    public void Restart()
    {
        Run("Restart.ps1");
    }

    public SingBoxConfigFSModel GetConfig()
    {
        var output = Run("GetConfig.ps1");
        return JsonSerializer.Deserialize<SingBoxConfigFSModel>(output, JsonOptions) ?? new SingBoxConfigFSModel();
    }

    private string Run(string scriptFile, IReadOnlyDictionary<string, string>? args = null)
    {
        return RunScript("SingBoxExecutor", scriptFile, args);
    }
}
