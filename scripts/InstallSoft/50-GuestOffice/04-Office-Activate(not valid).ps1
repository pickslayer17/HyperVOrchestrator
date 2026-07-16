# 50-GuestOffice / 04 — PROOF: sign in the Intapp account via OAuth device-code flow.
# One interactive step: open the printed URL, enter the code, approve Okta on the phone. No Office UI.
# Standalone check for now — run it manually (inside the VM, or on the host to just test the auth path).
$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

# Microsoft Graph Command Line Tools — public client, device-code capable
$clientId = "14d82eec-204b-4c2f-b7e8-296a70dab67e"
$scope    = "openid profile offline_access https://graph.microsoft.com/User.Read"
$authBase = "https://login.microsoftonline.com/organizations/oauth2/v2.0"

$dc = Invoke-RestMethod -Method Post -Uri "$authBase/devicecode" -Body @{
    client_id = $clientId
    scope     = $scope
}

Write-Host ""
Write-Host "==> $($dc.message)"
Write-Host ""

$token = $null
$deadline = (Get-Date).AddSeconds([int]$dc.expires_in)
$interval = [int]$dc.interval
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds $interval
    try {
        $token = Invoke-RestMethod -Method Post -Uri "$authBase/token" -Body @{
            grant_type  = "urn:ietf:params:oauth:grant-type:device_code"
            client_id   = $clientId
            device_code = $dc.device_code
        }
        break
    } catch {
        $err = ""
        if ($_.ErrorDetails.Message) { $err = ($_.ErrorDetails.Message | ConvertFrom-Json).error }
        if ($err -eq "authorization_pending") { continue }
        if ($err -eq "slow_down") { $interval += 5; continue }
        throw "device-code failed: $err`n$($_.ErrorDetails.Message)"
    }
}
if (-not $token) { throw "timed out waiting for approval" }

$part = $token.id_token.Split('.')[1].Replace('-', '+').Replace('_', '/')
switch ($part.Length % 4) { 2 { $part += '==' } 3 { $part += '=' } }
$claims = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($part)) | ConvertFrom-Json

Write-Host "SIGNED IN OK"
Write-Host "  account       : $($claims.preferred_username)"
Write-Host "  name          : $($claims.name)"
Write-Host "  tenant        : $($claims.tid)"
Write-Host "  refresh token : $([bool]$token.refresh_token)"
