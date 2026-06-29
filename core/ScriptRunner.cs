using System.Diagnostics;
using System.Text;

namespace Orchestrator;

internal sealed record RunResult
{
    public required bool Found { get; init; }
    public required int ExitCode { get; init; }
    public string? Error { get; init; }
    public IReadOnlyList<(string Key, string Value)> Sets { get; init; } = [];
}

internal sealed class ScriptRunner
{

    private readonly IReadOnlyDictionary<string, string> _values;
    private readonly string _repoRoot;

    private readonly object _gate = new();
    private Process? _current;

    public ScriptRunner(IReadOnlyDictionary<string, string> values, string repoRoot)
    {
        _values = values;
        _repoRoot = repoRoot;
    }

    public RunResult Run(string scriptPath, Action<string> onStdout, Action<string> onStderr)
    {
        if (!File.Exists(scriptPath))
            return new RunResult { Found = false, ExitCode = -1, Error = $"script not found: {scriptPath}" };

        string interpolated;
        try
        {

            var injected = ScriptInjector.Inject(File.ReadAllText(scriptPath), _repoRoot);
            interpolated = ConfigInterpolator.Interpolate(injected, _values);
        }
        catch (InvalidOperationException ex)
        {
            return new RunResult { Found = false, ExitCode = -1, Error = ex.Message };
        }

        var target = ScriptDirectives.ParseTarget(interpolated);
        var finalText = target == ScriptTarget.Vm ? WrapForVm(interpolated) : interpolated;

        var (exit, sets) = RunPowerShell(finalText, onStdout, onStderr);
        return new RunResult { Found = true, ExitCode = exit, Sets = sets };
    }

    public void Cancel()
    {
        lock (_gate)
        {
            try { _current?.Kill(entireProcessTree: true); }
            catch {  }
        }
    }

    private (int exit, IReadOnlyList<(string, string)> sets) RunPowerShell(
        string scriptText, Action<string> onStdout, Action<string> onStderr)
    {
        var tempPath = Path.Combine(Path.GetTempPath(), $"orch-{Guid.NewGuid():N}.ps1");
        File.WriteAllText(tempPath, scriptText, new UTF8Encoding(encoderShouldEmitUTF8Identifier: true));

        var psi = new ProcessStartInfo
        {
            FileName = "powershell.exe",
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
        };
        psi.ArgumentList.Add("-NoProfile");
        psi.ArgumentList.Add("-ExecutionPolicy");
        psi.ArgumentList.Add("Bypass");
        psi.ArgumentList.Add("-File");
        psi.ArgumentList.Add(tempPath);

        var sets = new List<(string, string)>();
        var proc = new Process { StartInfo = psi };

        proc.OutputDataReceived += (_, e) =>
        {
            if (e.Data is null) return;
            lock (_gate)
            {
                var hit = StateStore.MatchSet(e.Data);
                if (hit is not null) sets.Add(hit.Value);
                else onStdout(e.Data);
            }
        };
        proc.ErrorDataReceived += (_, e) =>
        {
            if (e.Data is null) return;
            lock (_gate) onStderr(e.Data);
        };

        try
        {
            proc.Start();
            lock (_gate) _current = proc;

            proc.BeginOutputReadLine();
            proc.BeginErrorReadLine();

            proc.WaitForExit();
            return (proc.ExitCode, sets);
        }
        finally
        {
            lock (_gate) _current = null;
            proc.Dispose();
            try { File.Delete(tempPath); } catch { }
        }
    }

    private string WrapForVm(string body)
    {
        var vm = Require("vm.name");
        var user = Require("credentials.user");
        var pass = Require("credentials.password");

        var sb = new StringBuilder();
        sb.AppendLine("$ErrorActionPreference = 'Stop'");
        sb.AppendLine($"$__cred = New-Object System.Management.Automation.PSCredential('{Lit(user)}', (ConvertTo-SecureString '{Lit(pass)}' -AsPlainText -Force))");

        sb.AppendLine("try {");
        sb.AppendLine($"$__rc = Invoke-Command -VMName '{Lit(vm)}' -Credential $__cred -ErrorAction Stop -ScriptBlock {{");
        sb.AppendLine(body);
        sb.AppendLine("}");
        sb.AppendLine("exit ($__rc | Select-Object -Last 1)");
        sb.AppendLine("} catch { Write-Error $_.Exception.Message; exit 1 }");
        return sb.ToString();
    }

    private string Require(string key) =>
        _values.TryGetValue(key, out var v) && !string.IsNullOrEmpty(v)
            ? v
            : throw new InvalidOperationException($"$ScriptTarget = \"VM\" requires config value '{key}' to be set.");

    private static string Lit(string s) => s.Replace("'", "''");
}
