using System.Diagnostics;
using System.Text;

namespace Orchestrator;

// Результат выполнения одного .ps1. Вывод печатается ЖИВЬЁМ во время работы
// (через колбэки), поэтому текста stdout/stderr здесь нет — только исход.
internal sealed record RunResult
{
    public required bool Found { get; init; }     // файл найден и запущен
    public required int ExitCode { get; init; }
    public string? Error { get; init; }            // ошибка ДО запуска (нет файла / битый плейсхолдер)
    public IReadOnlyList<(string Key, string Value)> Sets { get; init; } = [];
}

// Слой ВЫПОЛНЕНИЯ. Берёт путь к .ps1, интерполирует @@config@@, решает по
// переменной $ScriptTarget где исполнять, при необходимости заворачивает тело в
// Invoke-Command (PSDirect + креды из конфига), гонит через powershell.exe.
//
// Вывод стримится ПОСТРОЧНО по мере поступления (onStdout/onStderr) — длинный
// шаг (DISM и т.п.) виден сразу, а не после завершения. Печатает вызывающий
// (через колбэки), runner Console не трогает.
//
// Текущий процесс хранится в _current, чтобы Cancel() (Ctrl+C из Program) мог
// убить его вместе с дочерними (dism/bcdboot) и вернуть управление в меню.
internal sealed class ScriptRunner
{
    // Живая карта значений. Та же ссылка, что у Program: по мере накопления
    // ::set интерполяция видит новые значения.
    private readonly IReadOnlyDictionary<string, string> _values;

    private readonly object _gate = new();
    private Process? _current;

    public ScriptRunner(IReadOnlyDictionary<string, string> values) => _values = values;

    public RunResult Run(string scriptPath, Action<string> onStdout, Action<string> onStderr)
    {
        if (!File.Exists(scriptPath))
            return new RunResult { Found = false, ExitCode = -1, Error = $"script not found: {scriptPath}" };

        string interpolated;
        try
        {
            interpolated = ConfigInterpolator.Interpolate(File.ReadAllText(scriptPath), _values);
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

    // Убить текущий процесс вместе с деревом (dism, bcdboot, vmconnect...).
    // Зовётся из обработчика Ctrl+C. Безопасно, если ничего не запущено.
    public void Cancel()
    {
        lock (_gate)
        {
            try { _current?.Kill(entireProcessTree: true); }
            catch { /* уже завершился — ок */ }
        }
    }

    // temp .ps1 + -File: run text as one real script (correct remoting, honest
    // exit/errors) — not -Command - via stdin. write -> run -> delete.
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

        // ::set-строки в вывод не печатаем — собираем в sets. lock сериализует
        // печать stdout/stderr (события приходят из разных потоков) и защищает sets.
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

            proc.WaitForExit(); // без таймаута: дожидается и выхода, и слива буферов
            return (proc.ExitCode, sets);
        }
        finally
        {
            lock (_gate) _current = null;
            proc.Dispose();
            try { File.Delete(tempPath); } catch { }
        }
    }

    // Завернуть тело в Invoke-Command -VMName с кредами из конфига.
    // Недоступность ВМ или throw внутри тела -> терминирующая ошибка -> catch ->
    // exit 1. Поэтому VM-скриптам не нужно самим строить креды и проверять доступность.
    private string WrapForVm(string body)
    {
        var vm = Require("vm.name");
        var user = Require("credentials.user");
        var pass = Require("credentials.password");

        var sb = new StringBuilder();
        sb.AppendLine("$ErrorActionPreference = 'Stop'");
        sb.AppendLine($"$__cred = New-Object System.Management.Automation.PSCredential('{Lit(user)}', (ConvertTo-SecureString '{Lit(pass)}' -AsPlainText -Force))");
        sb.AppendLine("try {");
        sb.AppendLine($"Invoke-Command -VMName '{Lit(vm)}' -Credential $__cred -ErrorAction Stop -ScriptBlock {{");
        sb.AppendLine(body);
        sb.AppendLine("}");
        sb.AppendLine("} catch { Write-Error $_.Exception.Message; exit 1 }");
        return sb.ToString();
    }

    private string Require(string key) =>
        _values.TryGetValue(key, out var v) && !string.IsNullOrEmpty(v)
            ? v
            : throw new InvalidOperationException($"$ScriptTarget = \"VM\" requires config value '{key}' to be set.");

    private static string Lit(string s) => s.Replace("'", "''");
}
