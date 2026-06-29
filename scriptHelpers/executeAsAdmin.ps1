$cred = New-Object System.Management.Automation.PSCredential('TestUser', (ConvertTo-SecureString 'Test1234!' -AsPlainText -Force))
Invoke-Command -VMName TestRunner2 -Credential $cred -ScriptBlock {
  $tn  = 'system_crack_test'
  $cmd = 'whoami > C:\system_cracked.txt'

  schtasks /create /tn $tn /ru SYSTEM /sc once /st 00:00 /tr "cmd /c $cmd" /f | Out-Null
  schtasks /run /tn $tn | Out-Null

  # ждём, пока задача выйдет из Running
  for ($i = 0; $i -lt 30; $i++) {
    $st = (schtasks /query /tn $tn /fo csv /nh) -replace '"',''
    if ($st -notmatch 'Running') { break }
    Start-Sleep -Milliseconds 300
  }

  schtasks /delete /tn $tn /f | Out-Null

  if (Test-Path C:\system_cracked.txt) {
    [PSCustomObject]@{
      Exists    = $true
      Content   = (Get-Content C:\system_cracked.txt -Raw).Trim()
      FileOwner = (Get-Acl C:\system_cracked.txt).Owner
    }
  } else {
    [PSCustomObject]@{ Exists = $false }
  }
}
