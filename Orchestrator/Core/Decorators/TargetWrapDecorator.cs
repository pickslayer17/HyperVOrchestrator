using System.Text.RegularExpressions;
using Orchestrator.Helpers;

namespace Orchestrator.Core.Decorators;

internal sealed class TargetWrapDecorator : IScriptDecorator
{
    private const string TargetPattern = @"^\s*\$ScriptTarget\s*=\s*[""']?(Host|VM)[""']?";

    private const string WrapTemplate =
        @"$ErrorActionPreference = 'Stop'
        $__cred = New-Object System.Management.Automation.PSCredential('{1}', (ConvertTo-SecureString '{2}' -AsPlainText -Force))
        try {{
        $__rc = Invoke-Command -VMName '{3}' -Credential $__cred -ErrorAction Stop -ScriptBlock {{
        {0}
        }}
        exit ($__rc | Select-Object -Last 1)
        }} catch {{ Write-Error $_.Exception.Message; exit 1 }}";

    private readonly string _vmName;
    private readonly string _user;
    private readonly string _password;

    public TargetWrapDecorator(string vmName, string user, string password)
    {
        _vmName = vmName;
        _user = user;
        _password = password;
    }

    public string Format(string script)
    {
        if (!IsVmTarget(script))
            return script;

        var user = Escape(_user);
        var password = Escape(_password);
        var vmName = Escape(_vmName);
        var result = string.Format(WrapTemplate, script, user, password, vmName);
        return result;
    }

    private static bool IsVmTarget(string script)
    {
        var match = RegexHelper.Get(TargetPattern, script, RegexOptions.Multiline | RegexOptions.IgnoreCase);
        var result = match.Success && match.Groups[1].Value.Equals("VM", StringComparison.OrdinalIgnoreCase);
        return result;
    }

    private static string Escape(string value)
    {
        var result = value.Replace("'", "''");
        return result;
    }
}
