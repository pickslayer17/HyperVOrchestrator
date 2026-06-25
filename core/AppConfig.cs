using Microsoft.Extensions.Configuration;

namespace Orchestrator;

// Типизированный конфиг. Биндится из config/default.config.json,
// поверх мерджится config/local.config.json (реальные значения, в .gitignore).
internal sealed class AppConfig
{
    public VmConfig Vm { get; init; } = new();
    public CredentialsConfig Credentials { get; init; } = new();
    public NetworkConfig Network { get; init; } = new();
    public PathsConfig Paths { get; init; } = new();
    public OfficeConfig Office { get; init; } = new();

    // Загружает default + local, биндит в AppConfig, резолвит относительные
    // пути в paths.* в абсолютные от корня репо.
    public static AppConfig Load(string repoRoot)
    {
        var configDir = Path.Combine(repoRoot, "config");
        var config = new ConfigurationBuilder()
            .AddJsonFile(Path.Combine(configDir, "default.config.json"), optional: false)
            .AddJsonFile(Path.Combine(configDir, "local.config.json"), optional: true)
            .Build();

        var app = config.Get<AppConfig>() ?? new AppConfig();
        app.Paths.ResolveAgainst(repoRoot);
        return app;
    }
}

internal sealed class VmConfig
{
    public string Name { get; init; } = "";
    public int MemoryGb { get; init; }
    public int CpuCount { get; init; }
    public int DiskSizeGb { get; init; }
}

internal sealed class CredentialsConfig
{
    public string User { get; init; } = "";
    public string Password { get; init; } = "";
}

internal sealed class NetworkConfig
{
    public string SwitchName { get; init; } = "";
    public string HostIp { get; init; } = "";
    public string VmIp { get; init; } = "";
    public int Prefix { get; init; }
    public int ProxyPort { get; init; }
    public int RdpForwardPort { get; init; }
    public string DnsServer { get; init; } = "";
}

internal sealed class PathsConfig
{
    public string WindowsIso { get; set; } = "";
    public string UnattendXml { get; set; } = "";
    public string OfficeArchive { get; set; } = "";

    // Относительные пути из конфига -> абсолютные от корня репо.
    // Пустые и уже-абсолютные оставляем как есть.
    public void ResolveAgainst(string repoRoot)
    {
        WindowsIso = Resolve(repoRoot, WindowsIso);
        UnattendXml = Resolve(repoRoot, UnattendXml);
        OfficeArchive = Resolve(repoRoot, OfficeArchive);
    }

    private static string Resolve(string repoRoot, string path) =>
        string.IsNullOrEmpty(path) || Path.IsPathRooted(path)
            ? path
            : Path.GetFullPath(Path.Combine(repoRoot, path));
}

internal sealed class OfficeConfig
{
    public string Channel { get; init; } = "";
    public string Edition { get; init; } = "";
    public string[] Apps { get; init; } = [];
}
