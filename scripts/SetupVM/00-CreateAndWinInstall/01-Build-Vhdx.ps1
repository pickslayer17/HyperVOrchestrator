# build bootable vhdx: gpt -> dism apply -> bcdboot -> unattend

$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$vmName = "@@state.vm.name@@"
$windowsIso = "@@paths.windowsIso@@"
$unattendXml = "@@paths.unattendXml@@"
$diskSizeGb = @@vm.diskSizeGb@@
$vhdPath = Join-Path "@@paths.vmDir@@" "$vmName.vhdx"

# free drive letters
$usedLetters = @()
$usedLetters += (Get-Volume | Where-Object { $_.DriveLetter } | ForEach-Object { $_.DriveLetter })
$usedLetters += (Get-Partition | Where-Object { $_.DriveLetter } | ForEach-Object { $_.DriveLetter })
$freeLetters = [char[]](68..90) | Where-Object { $_ -notin $usedLetters }
if ($freeLetters.Count -lt 2) { throw "Not enough free drive letters" }
$efiLetter = [string]$freeLetters[0]
$windowsLetter = [string]$freeLetters[1]
Write-Host "Using drive letters: EFI=$efiLetter, Windows=$windowsLetter"

# create + partition vhdx
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $vhdPath) | Out-Null
Write-Host "Creating VHDX..."
New-VHD -Path $vhdPath -SizeBytes $diskSizeGb -Dynamic
Mount-VHD -Path $vhdPath
$diskNumber = (Get-VHD -Path $vhdPath).DiskNumber
Initialize-Disk -Number $diskNumber -PartitionStyle GPT

$efiPartition = New-Partition -DiskNumber $diskNumber -Size 512MB -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}'
Format-Volume -Partition $efiPartition -FileSystem FAT32 -NewFileSystemLabel "EFI" -Confirm:$false
$efiPartition | Set-Partition -NewDriveLetter $efiLetter

New-Partition -DiskNumber $diskNumber -Size 128MB -GptType '{e3c9e316-0b5c-4db8-817d-f92df00215ae}'

$windowsPartition = New-Partition -DiskNumber $diskNumber -UseMaximumSize
Format-Volume -Partition $windowsPartition -FileSystem NTFS -NewFileSystemLabel "Windows" -Confirm:$false
$windowsPartition | Set-Partition -NewDriveLetter $windowsLetter

Write-Host "VHDX partitioned. EFI=${efiLetter}:, Windows=${windowsLetter}:"

try {
    # apply image
    Write-Host "Mounting Windows ISO..."
    $mountedIso = Mount-DiskImage -ImagePath $windowsIso -PassThru
    $isoLetter = ($mountedIso | Get-Volume).DriveLetter

    Write-Host "Applying Windows image with DISM (this takes a few minutes)..."
    $wimPath = "${isoLetter}:\sources\install.wim"
    if (-not (Test-Path $wimPath)) { throw "install.wim not found at $wimPath" }

    $imageInfo = dism /get-imageinfo /imagefile:$wimPath
    Write-Host $imageInfo

    dism /apply-image /imagefile:$wimPath /index:1 /applydir:${windowsLetter}:\
    if ($LASTEXITCODE -ne 0) { throw "DISM apply-image failed with code $LASTEXITCODE" }
    Write-Host "Image applied."

    # uefi boot
    Write-Host "Setting up UEFI boot..."
    bcdboot ${windowsLetter}:\Windows /s ${efiLetter}: /f UEFI
    if ($LASTEXITCODE -ne 0) { throw "bcdboot failed with code $LASTEXITCODE" }
    Write-Host "Boot configured."

    # unattend
    $pantherDir = "${windowsLetter}:\Windows\Panther"
    mkdir $pantherDir -Force

    [xml]$unattend = Get-Content $unattendXml -Raw
    $ns = New-Object Xml.XmlNamespaceManager $unattend.NameTable
    $ns.AddNamespace("u", "urn:schemas-microsoft-com:unattend")

    $unattend.SelectSingleNode("//u:ComputerName", $ns).InnerText = "@@state.vm.name@@"

    $localAccount = $unattend.SelectSingleNode("//u:UserAccounts/u:LocalAccounts/u:LocalAccount", $ns)
    $localAccount.SelectSingleNode("u:Name", $ns).InnerText = "@@credentials.user@@"
    $localAccount.SelectSingleNode("u:Password/u:Value", $ns).InnerText = "@@credentials.password@@"

    $autoLogon = $unattend.SelectSingleNode("//u:AutoLogon", $ns)
    $autoLogon.SelectSingleNode("u:Username", $ns).InnerText = "@@credentials.user@@"
    $autoLogon.SelectSingleNode("u:Password/u:Value", $ns).InnerText = "@@credentials.password@@"

    [IO.File]::WriteAllText("$pantherDir\unattend.xml", $unattend.OuterXml, [Text.UTF8Encoding]::new($false))
    Write-Host "Unattend.xml written to Panther."
}
finally {
    # cleanup mounts + drive letters
    Write-Host "Cleaning up drive letters and mounts..."
    Get-Partition -DiskNumber $diskNumber -ErrorAction SilentlyContinue |
        Where-Object { $_.DriveLetter } |
        ForEach-Object {
            Remove-PartitionAccessPath -DiskNumber $_.DiskNumber -PartitionNumber $_.PartitionNumber -AccessPath "$($_.DriveLetter):\" -ErrorAction SilentlyContinue
        }
    Dismount-DiskImage -ImagePath $windowsIso -ErrorAction SilentlyContinue
    Dismount-VHD -Path $vhdPath -ErrorAction SilentlyContinue
    Write-Host "Cleanup done."
}

Write-Host "VHDX ready: $vhdPath"
