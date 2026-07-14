using System.Text;

namespace Orchestrator.Core.Decorators;

internal sealed class TargetWrapDecorator : IScriptDecorator
{
    private const string WrapTemplate =
        @"$ErrorActionPreference = 'Stop'
        $__cred = New-Object System.Management.Automation.PSCredential('{1}', (ConvertTo-SecureString '{2}' -AsPlainText -Force))
        try {{
        Invoke-Command -VMName '{3}' -Credential $__cred -ErrorAction Stop -ScriptBlock {{
        $__file = Join-Path $env:TEMP (""orch_"" + [guid]::NewGuid().ToString('N') + "".ps1"")
        $__content = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('{0}'))
        Set-Content -Path $__file -Value $__content -Encoding UTF8
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $__file
        $__guestExit = $LASTEXITCODE
        Remove-Item $__file -Force -ErrorAction SilentlyContinue
        Write-Output ""<<exit::$__guestExit>>""
        }}
        exit 0
        }} catch {{ Write-Error $_.Exception.Message; exit 1 }}";

    private readonly StateKeeper _stateKeeper;
    private readonly string _user;
    private readonly string _password;

    public TargetWrapDecorator(StateKeeper stateKeeper, string user, string password)
    {
        _stateKeeper = stateKeeper;
        _user = user;
        _password = password;
    }

    public string Format(string script)
    {
        var encoded = Convert.ToBase64String(Encoding.UTF8.GetBytes(script));
        var user = Escape(_user);
        var password = Escape(_password);
        var vmName = Escape(_stateKeeper.CurrentVm?.Name ?? "");
        var result = string.Format(WrapTemplate, encoded, user, password, vmName);
        return result;
    }

    private static string Escape(string value)
    {
        var result = value.Replace("'", "''");
        return result;
    }
}
