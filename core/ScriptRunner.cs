using System.Diagnostics;
using System.Text;

namespace Orchestrator;

// Результат выполнения одного .ps1.
internal sealed record RunResult
{
    public required bool Found { get; init; }     // файл найден и запущен
    public required int ExitCode { get; init; }
    public string Stdout { get; init; } = "";     // уже без ::set-строк
    public string Stderr { get; init; } = "";
    public string? Error { get; init; }            // ошибка ДО запуска (нет файла / битый плейсхолдер)
    public IReadOnlyList<(string Key, string Value)> Sets { get; init; } = [];
}

// Слой ВЫПОЛНЕНИЯ. Берёт путь к .ps1, интерполирует @@config@@, решает по
// директиве #:target где исполнять, при необходимости заворачивает тело в
// Invoke-Command (PSDirect + креды из конфига), гонит через powershell.exe.
//
// Чистая механика: ничего не печатает сам — возвращает RunResult, печатает
// вызывающий (Program/Ui). Так вывод отделён от выполнения.
internal sealed class ScriptRunner
{
    // Живая карта значений. Та же ссылка, что у Program: по мере накопления
    // ::set интерполяция видит новые значения.
    private readonly IReadOnlyDictionary<string, string> _values;

    public ScriptRunner(IReadOnlyDictionary<string, string> values) => _values = values;

    public RunResult Run(string scriptPath)
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

        var (rawStdout, stderr, exit) = RunPowerShell(finalText);
        var (cleanStdout, sets) = StateStore.ExtractSets(rawStdout);

        return new RunResult
        {
            Found = true,
            ExitCode = exit,
            Stdout = cleanStdout,
            Stderr = stderr,
            Sets = sets,
        };
    }

    // Завернуть тело в Invoke-Command -VMName с кредами из конфига.
    // Значения уже впечатаны интерполяцией, -ArgumentList не нужен —
    // тело self-contained. Кавычки в кредах экранируем удвоением (PS-литерал).
    private string WrapForVm(string body)
    {
        var vm = Require("vm.name");
        var user = Require("credentials.user");
        var pass = Require("credentials.password");

        // Недоступность ВМ или throw внутри тела -> терминирующая ошибка ->
        // catch -> exit 1. Поэтому VM-скриптам (и check, и основным) не нужно
        // самим строить креды и проверять доступность: ошибка = чистый провал.
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

    // Готовый текст -> powershell.exe через stdin (-Command -), без временных файлов.
    private static (string stdout, string stderr, int exit) RunPowerShell(string scriptText)
    {
        var psi = new ProcessStartInfo
        {
            FileName = "powershell.exe",
            RedirectStandardInput = true,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
        };
        psi.ArgumentList.Add("-NoProfile");
        psi.ArgumentList.Add("-ExecutionPolicy");
        psi.ArgumentList.Add("Bypass");
        psi.ArgumentList.Add("-Command");
        psi.ArgumentList.Add("-");

        using var proc = Process.Start(psi)!;
        proc.StandardInput.Write(scriptText);
        proc.StandardInput.Close();

        var stdout = proc.StandardOutput.ReadToEnd();
        var stderr = proc.StandardError.ReadToEnd();
        proc.WaitForExit();

        return (stdout, stderr, proc.ExitCode);
    }
}
