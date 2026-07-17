$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$guestDir = "@@paths.guestOfficeDir@@"
$wanted = @("@@office.apps@@".Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
$allApps = @('Access','Excel','Groove','Lync','OneDrive','OneNote','Outlook','PowerPoint','Publisher','Word','Teams')
$excluded = $allApps | Where-Object { $wanted -notcontains $_ }
$excludeLines = ($excluded | ForEach-Object { "      <ExcludeApp ID=`"$_`" />" }) -join "`r`n"

$xml = @"
<Configuration>
  <Add OfficeClientEdition="@@office.edition@@" Channel="@@office.channel@@" SourcePath="$guestDir">
    <Product ID="O365ProPlusRetail">
      <Language ID="en-us" />
$excludeLines
    </Product>
  </Add>
  <Property Name="FORCEAPPSHUTDOWN" Value="TRUE" />
  <Display Level="None" AcceptEULA="TRUE" />
  <Updates Enabled="FALSE" />
</Configuration>
"@

Set-Content -Path (Join-Path $guestDir "configuration.xml") -Value $xml -Encoding UTF8
Write-Host "config written; installing: $($wanted -join ', ')"
