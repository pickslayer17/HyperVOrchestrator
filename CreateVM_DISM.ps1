$ErrorActionPreference = "Stop"

# === НАСТРОЙКИ ===
$vmName = "TestRunner"
$vmPath = "D:\VMs"
$vhdPath = "$vmPath\$vmName.vhdx"
$windowsIso = "$vmPath\26200.6584.250915-1905.25h2_ge_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso"
$unattendXml = "$vmPath\unattend\autounattend.xml"

# === ПРОВЕРКИ ===
if (-not (Test-Path $windowsIso)) { throw "Windows ISO not found: $windowsIso" }
if (-not (Test-Path $unattendXml)) { throw "autounattend.xml not found: $unattendXml" }

# === ПОИСК СВОБОДНЫХ БУКВ ===
$usedLetters = @()
$usedLetters += (Get-Volume | Where-Object { $_.DriveLetter } | ForEach-Object { $_.DriveLetter })
$usedLetters += (Get-Partition | Where-Object { $_.DriveLetter } | ForEach-Object { $_.DriveLetter })
$freeLetters = [char[]](68..90) | Where-Object { $_ -notin $usedLetters }  # D-Z
if ($freeLetters.Count -lt 2) { throw "Not enough free drive letters" }
$efiLetter = [string]$freeLetters[0]
$winLetter = [string]$freeLetters[1]
Write-Host "Using drive letters: EFI=$efiLetter, Windows=$winLetter"

# === ОЧИСТКА ===
$existingVm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
if ($existingVm) {
    Write-Host "Removing existing VM '$vmName'..."
    if ($existingVm.State -ne 'Off') { Stop-VM -Name $vmName -Force }
    Remove-VM -Name $vmName -Force
}
if (Test-Path $vhdPath) {
    Dismount-VHD -Path $vhdPath -ErrorAction SilentlyContinue
    Remove-Item $vhdPath -Force
}

# === 1. СОЗДАТЬ И РАЗМЕТИТЬ VHDX ===
Write-Host "Creating VHDX..."
New-VHD -Path $vhdPath -SizeBytes 40GB -Dynamic
Mount-VHD -Path $vhdPath
$diskNumber = (Get-VHD -Path $vhdPath).DiskNumber
Initialize-Disk -Number $diskNumber -PartitionStyle GPT

# EFI раздел (512MB, FAT32)
$efi = New-Partition -DiskNumber $diskNumber -Size 512MB -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}'
Format-Volume -Partition $efi -FileSystem FAT32 -NewFileSystemLabel "EFI" -Confirm:$false
$efi | Set-Partition -NewDriveLetter $efiLetter

# MSR раздел (128MB)
New-Partition -DiskNumber $diskNumber -Size 128MB -GptType '{e3c9e316-0b5c-4db8-817d-f92df00215ae}'

# Windows раздел (остаток)
$win = New-Partition -DiskNumber $diskNumber -UseMaximumSize
Format-Volume -Partition $win -FileSystem NTFS -NewFileSystemLabel "Windows" -Confirm:$false
$win | Set-Partition -NewDriveLetter $winLetter

Write-Host "VHDX partitioned. EFI=${efiLetter}:, Windows=${winLetter}:"

try {
    # === 2. СМОНТИРОВАТЬ ISO И ПРИМЕНИТЬ ОБРАЗ ===
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

    # === 3. УСТАНОВИТЬ ЗАГРУЗЧИК ===
    Write-Host "Setting up UEFI boot..."
    bcdboot ${winLetter}:\Windows /s ${efiLetter}: /f UEFI
    if ($LASTEXITCODE -ne 0) { throw "bcdboot failed with code $LASTEXITCODE" }
    Write-Host "Boot configured."

    # === 4. ПОЛОЖИТЬ UNATTEND.XML ДЛЯ OOBE ===
    $pantherDir = "${winLetter}:\Windows\Panther"
    mkdir $pantherDir -Force
    Copy-Item $unattendXml "$pantherDir\unattend.xml"
    Write-Host "Unattend.xml copied to Panther."
}
finally {
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

# === 5. СОЗДАТЬ VM ===
Write-Host "Creating VM..."
New-VM -Name $vmName -MemoryStartupBytes 4GB -Generation 2 -VHDPath $vhdPath
Set-VMProcessor -VMName $vmName -Count 4
Set-VMKeyProtector -VMName $vmName -NewLocalKeyProtector
Enable-VMTPM -VMName $vmName
Write-Host "VM created with TPM."

# === 6. ЗАПУСТИТЬ ===
Write-Host "Starting VM..."
Start-VM -VMName $vmName
vmconnect localhost $vmName
Write-Host "Done. Windows should boot directly into setup (specialize + OOBE)."
