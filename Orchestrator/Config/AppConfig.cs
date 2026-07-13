using Microsoft.Extensions.Configuration;

namespace Orchestrator.Config;

public class AppConfig
{
    public VmConfig Vm { get; init; } = new();
    public CredentialsConfig Credentials { get; init; } = new();
    public NetworkConfig Network { get; init; } = new();
    public PathsConfig Paths { get; init; } = new();
    public DotnetConfig Dotnet { get; init; } = new();
    public FlauiConfig Flaui { get; init; } = new();
    public OfficeConfig Office { get; init; } = new();

    public static AppConfig Current { get; private set; } = new();

    public static AppConfig Load(string repoRoot)
    {
        var config = new ConfigurationBuilder()
            .AddJsonFile(Path.Combine(repoRoot, "default.config.json"), optional: false)
            .AddJsonFile(Path.Combine(repoRoot, "local.config.json"), optional: true)
            .Build();

        var app = config.Get<AppConfig>() ?? new AppConfig();
        app.Paths.ResolveAgainst(repoRoot);
        Current = app;
        var result = app;
        return result;
    }
}

public sealed class VmConfig
{
    public string Name { get; init; } = "";
    public string Host { get; init; } = "";
    public string MemoryGb { get; init; } = "";
    public int CpuCount { get; init; }
    public string DiskSizeGb { get; init; } = "";
    public int VideoWidth { get; init; }
    public int VideoHeight { get; init; }
    public string TimeZone { get; init; } = "";
}

public sealed class CredentialsConfig
{
    public string User { get; init; } = "";
    public string Password { get; init; } = "";
}

public sealed class NetworkConfig
{
    public string SwitchName { get; init; } = "";
    public string NatName { get; init; } = "";
    public string DefaultNatHostIp { get; init; } = "";
    public int SubnetPrefixLength { get; init; }
    public string DnsServer { get; init; } = "";
    public string ForwardBind { get; init; } = "";
}

public sealed class PathsConfig
{
    public string VmDir { get; set; } = "";
    public string WindowsIso { get; set; } = "";
    public string UnattendTemplate { get; set; } = "";
    public string UnattendXml { get; set; } = "";
    public string OfficeArchive { get; set; } = "";
    public string StateFile { get; set; } = "";
    public string DotnetInstallDir { get; init; } = "";
    public string PythonServer { get; set; } = "";

    public void ResolveAgainst(string repoRoot)
    {
        WindowsIso = Resolve(repoRoot, WindowsIso);
        UnattendTemplate = Resolve(repoRoot, UnattendTemplate);
        UnattendXml = Resolve(repoRoot, UnattendXml);
        OfficeArchive = Resolve(repoRoot, OfficeArchive);
        StateFile = Resolve(repoRoot, StateFile);
        PythonServer = Resolve(repoRoot, PythonServer);
    }

    private static string Resolve(string repoRoot, string path)
    {
        var result = string.IsNullOrEmpty(path) || Path.IsPathRooted(path)
            ? path
            : Path.GetFullPath(Path.Combine(repoRoot, path));
        return result;
    }
}

public sealed class DotnetConfig
{
    public string Channel { get; init; } = "";
    public string Quality { get; init; } = "";
    public string InstallScriptUrl { get; init; } = "";
}

public sealed class FlauiConfig
{
    public string ProjectName { get; init; } = "";
    public string BaseFramework { get; init; } = "";
    public string TargetFramework { get; init; } = "";
    public string Package { get; init; } = "";
}

public sealed class OfficeConfig
{
    public string Channel { get; init; } = "";
    public string Edition { get; init; } = "";
    public string[] Apps { get; init; } = [];
}
