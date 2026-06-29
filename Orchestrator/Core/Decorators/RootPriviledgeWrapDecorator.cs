using System.Text.RegularExpressions;
using Orchestrator.Helpers;

namespace Orchestrator.Core.Decorators;

internal sealed class RootPriviledgeWrapDecorator : IScriptDecorator
{
    private const string RootPattern = @"^\s*\$RootPriviledges\s*=\s*\$(true|false)";

    private const string WrapTemplate =
@"$__guid = [guid]::NewGuid().ToString('N')
$__taskFile = ""C:\temp\orch_$__guid.ps1""
$__taskResult = ""C:\temp\orch_$__guid.out""
New-Item -ItemType Directory -Path 'C:\temp' -Force | Out-Null
$__body = @'
try {{
{0}
}} catch {{ $_.Exception.Message }}
'@
Set-Content -Path $__taskFile -Value $__body -Encoding UTF8
$__tn = ""orch_root_$__guid""
schtasks /create /tn $__tn /ru SYSTEM /sc once /st 00:00 /tr ""cmd /c powershell.exe -NoProfile -ExecutionPolicy Bypass -File $__taskFile > $__taskResult 2>&1"" /f 2>$null | Out-Null
schtasks /run /tn $__tn 2>$null | Out-Null
for ($__i = 0; $__i -lt 600; $__i++) {{
    $__st = (schtasks /query /tn $__tn /fo csv /nh) -replace '""', ''
    if ($__st -notmatch 'Running') {{ break }}
    Start-Sleep -Milliseconds 300
}}
# schtasks /delete /tn $__tn /f | Out-Null
# Remove-Item -Path $__taskFile -Force -ErrorAction SilentlyContinue
if (Test-Path $__taskResult) {{ Get-Content $__taskResult | ForEach-Object {{ Write-Host $_ }} }}";

    public string Format(string script)
    {
        if (!HasRootPriviledges(script))
            return script;

        var result = string.Format(WrapTemplate, script);
        return result;
    }

    private static bool HasRootPriviledges(string script)
    {
        var match = RegexHelper.Get(RootPattern, script, RegexOptions.Multiline | RegexOptions.IgnoreCase);
        var result = match.Success && match.Groups[1].Value.Equals("true", StringComparison.OrdinalIgnoreCase);
        return result;
    }
}
