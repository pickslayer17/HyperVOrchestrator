# build bootable vhdx: gpt -> dism apply -> bcdboot -> unattend

$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$vmName = "@@vm.name@@"
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
$winLetter = [string]$freeLetters[1]
Write-Host "Using drive letters: EFI=$efiLetter, Windows=$winLetter"

# create + partition vhdx
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $vhdPath) | Out-Null
Write-Host "Creating VHDX..."
New-VHD -Path $vhdPath -SizeBytes $diskSizeGb -Dynamic
Mount-VHD -Path $vhdPath
$diskNumber = (Get-VHD -Path $vhdPath).DiskNumber
Initialize-Disk -Number $diskNumber -PartitionStyle GPT

$efi = New-Partition -DiskNumber $diskNumber -Size 512MB -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}'
Format-Volume -Partition $efi -FileSystem FAT32 -NewFileSystemLabel "EFI" -Confirm:$false
$efi | Set-Partition -NewDriveLetter $efiLetter

New-Partition -DiskNumber $diskNumber -Size 128MB -GptType '{e3c9e316-0b5c-4db8-817d-f92df00215ae}'

$win = New-Partition -DiskNumber $diskNumber -UseMaximumSize
Format-Volume -Partition $win -FileSystem NTFS -NewFileSystemLabel "Windows" -Confirm:$false
$win | Set-Partition -NewDriveLetter $winLetter

Write-Host "VHDX partitioned. EFI=${efiLetter}:, Windows=${winLetter}:"

try {
    # apply image
    Write-Host "Mounting Windows ISO..."
    $mountResult = Mount-DiskImage -ImagePath $windowsIso -PassThru
    $isoLetter = ($mountResult | Get-Volume).DriveLetter

    Write-Host "Applying Windows image with DISM (this takes a few minutes)..."
    $wimPath = "${isoLetter}:\sources\install.wim"
    if (-not (Test-Path $wimPath)) { throw "install.wim not found at $wimPath" }

    $imageInfo = dism /get-imageinfo /imagefile:$wimPath
    Write-Host $imageInfo

    dism /apply-image /imagefile:$wimPath /index:1 /applydir:${winLetter}:\
    if ($LASTEXITCODE -ne 0) { throw "DISM apply-image failed with code $LASTEXITCODE" }
    Write-Host "Image applied."

    # uefi boot
    Write-Host "Setting up UEFI boot..."
    bcdboot ${winLetter}:\Windows /s ${efiLetter}: /f UEFI
    if ($LASTEXITCODE -ne 0) { throw "bcdboot failed with code $LASTEXITCODE" }
    Write-Host "Boot configured."

    # unattend
    $pantherDir = "${winLetter}:\Windows\Panther"
    mkdir $pantherDir -Force
    Copy-Item $unattendXml "$pantherDir\unattend.xml"
    Write-Host "Unattend.xml copied to Panther."
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
