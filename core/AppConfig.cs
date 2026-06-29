using Microsoft.Extensions.Configuration;

namespace Orchestrator;

internal sealed class AppConfig
{
    public VmConfig Vm { get; init; } = new();
    public CredentialsConfig Credentials { get; init; } = new();
    public NetworkConfig Network { get; init; } = new();
    public PathsConfig Paths { get; init; } = new();
    public DotnetConfig Dotnet { get; init; } = new();
    public FlauiConfig Flaui { get; init; } = new();
    public OfficeConfig Office { get; init; } = new();

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
    public string MemoryGb { get; init; } = "";
    public int CpuCount { get; init; }
    public string DiskSizeGb { get; init; } = "";
    public int VideoWidth { get; init; }
    public int VideoHeight { get; init; }
    public string TimeZone { get; init; } = "";
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

    public string VmDir { get; set; } = "";
    public string WindowsIso { get; set; } = "";
    public string UnattendTemplate { get; set; } = "";
    public string UnattendXml { get; set; } = "";
    public string OfficeArchive { get; set; } = "";

    public string StateFile { get; set; } = "";

    public string DotnetInstallDir { get; init; } = "";

    public void ResolveAgainst(string repoRoot)
    {
        WindowsIso = Resolve(repoRoot, WindowsIso);
        UnattendTemplate = Resolve(repoRoot, UnattendTemplate);
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
