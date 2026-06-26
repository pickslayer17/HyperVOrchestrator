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
    public DotnetConfig Dotnet { get; init; } = new();
    public FlauiConfig Flaui { get; init; } = new();
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
    public string MemoryGb { get; init; } = "";   // "4GB" — PowerShell-литерал размера
    public int CpuCount { get; init; }
    public string DiskSizeGb { get; init; } = ""; // "40GB" — PowerShell-литерал размера
    public int VideoWidth { get; init; }
    public int VideoHeight { get; init; }
}

internal sealed class CredentialsConfig
{
    public string User { get; init; } = "";
    public string Password { get; init; } = "";
}

internal sealed class NetworkConfig
{
    public string SwitchName { get; init; } = "";
    public string NatName { get; init; } = "";
    public string HostIp { get; init; } = "";
    public string VmIp { get; init; } = "";
    public int Prefix { get; init; }
    public int ProxyPort { get; init; }
    public int RdpForwardPort { get; init; }
    public string DnsServer { get; init; } = "";
    public string GuestInterfaceAlias { get; init; } = "";
}

internal sealed class PathsConfig
{
    // Абсолютная директория, куда ставится ВМ. Полный путь VHDX собираем сами:
    // VmDir + vm.name + ".vhdx". В резолве не участвует — уже абсолютный.
    public string VmDir { get; set; } = "";
    public string WindowsIso { get; set; } = "";
    public string UnattendXml { get; set; } = "";
    public string OfficeArchive { get; set; } = "";

    // Файл состояния (динамика, вычисленная на лету) — относительный от корня репо.
    public string StateFile { get; set; } = "";

    // Гостевые пути ВНУТРИ ВМ (Windows-абсолютные) — НЕ резолвим от корня хоста.
    public string DotnetInstallDir { get; init; } = "";

    // Хостовые относительные пути из конфига -> абсолютные от корня репо.
    // Пустые и уже-абсолютные оставляем как есть. Гостевые пути не трогаем.
    public void ResolveAgainst(string repoRoot)
    {
        WindowsIso = Resolve(repoRoot, WindowsIso);
        UnattendXml = Resolve(repoRoot, UnattendXml);
        OfficeArchive = Resolve(repoRoot, OfficeArchive);
        StateFile = Resolve(repoRoot, StateFile);
    }

    private static string Resolve(string repoRoot, string path) =>
        string.IsNullOrEmpty(path) || Path.IsPathRooted(path)
            ? path
            : Path.GetFullPath(Path.Combine(repoRoot, path));
}

internal sealed class DotnetConfig
{
    public string Channel { get; init; } = "";
    public string Quality { get; init; } = "";
    public string InstallScriptUrl { get; init; } = "";
}

internal sealed class FlauiConfig
{
    public string ProjectName { get; init; } = "";
    public string BaseFramework { get; init; } = "";
    public string TargetFramework { get; init; } = "";
    public string Package { get; init; } = "";
}

internal sealed class OfficeConfig
{
    public string Channel { get; init; } = "";
    public string Edition { get; init; } = "";
    public string[] Apps { get; init; } = [];
}
