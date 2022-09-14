# Various URLs and names
$AlpineRepo = "https://dl-cdn.alpinelinux.org/alpine"
$AlpineRelease = "v3.16"
$AlpineArch = "x86_64"
$AlpinePackageRoot = "$AlpineRepo/$AlpineRelease/main/$AlpineArch"
$AlpineReleasesRoot = "$AlpineRepo/$AlpineRelease/releases/$AlpineArch"
$AlpinePackages = ("musl", "busybox", "libgcc", "libstdc++", "icu", "icu-libs", "icu-data-en", "ncurses-terminfo-base")

$PowerShellUrl = "https://github.com/PowerShell/PowerShell/releases/download/v7.2.6/powershell-7.2.6-linux-alpine-x64.tar.gz"

# Helper functions
function Update-DownloadedFile([string]$Url) {
    $Name = [System.IO.Path]::GetFileName($Url)
    Write-Host "Getting $Name... " -NoNewline
    if (Test-Path $ExtDir/$Name) {
        $Head = Invoke-WebRequest -Method Head $Url
        $LastModified = [datetime]::ParseExact(
            $Head.Headers["Last-Modified"][0],
            "ddd, dd MMM yyyy HH:mm:ss 'GMT'",
            [cultureinfo]::InvariantCulture.DateTimeFormat,
            [System.Globalization.DateTimeStyles]::AssumeUniversal)
        $LastWriteTime = (Get-ChildItem $ExtDir/$Name).LastWriteTime
        if ($LastModified -lt $LastWriteTime) {
            Write-Host "old"
            return
        }
    }

    Write-Host "new " -NoNewline
    $ProgressPreference = "SilentlyContinue"
    Invoke-WebRequest $Url -OutFile $ExtDir/$Name
    $ProgressPreference = 'Continue'
    Write-Host (Format-DataLength ((Get-ChildItem $ExtDir/$Name).Length))
}

function Format-DataLength([int64]$Length) {
    $Prefixes = ("", "Ki", "Mi", "Gi")

    $Value = [double]$Length
    $Order = 1
    while (($Value -ge 1024) -and ($Order -lt $Prefixes.Length)) {
        $Order++
        $Value = $Value / 1024
    }

    [string]::Format("{0:0.##} {1}B", $Value, $Prefixes[$Order - 1])
}

function Expand-Tgz([string]$FileName, [string]$Destination) {
    Write-Host "Expanding $FileName... " -NoNewline

    $StartInfo = [System.Diagnostics.ProcessStartInfo]::new("tar")
    $StartInfo.RedirectStandardError = $true
    $StartInfo.RedirectStandardOutput = $true
    $StartInfo.UseShellExecute = $false
    $StartInfo.Arguments = "-zvxf `"$ExtDir/$FileName`" -C `"$Destination`" --exclude .PKGINFO --exclude .trigger --exclude `".SIGN.*`" --exclude `".post-*`""

    $Process = [System.Diagnostics.Process]::new()
    $Process.StartInfo = $StartInfo
    $Process.Start() | Out-Null
    $Process.WaitForExit()

    $ProcessOutput = $Process.StandardOutput.ReadToEnd() -split "`n"
    $ProcessError = $Process.StandardError.ReadToEnd() -split "`n" | Where-Object { $_ -cnotlike "tar: Ignoring*" }

    if ($Process.ExitCode -ne 0) {
        Write-Host "error"
        $ProcessError
        exit
    }

    Write-Host "$($ProcessOutput.Length) files"
}

# Prepare directories
$ExtDir = "ext"
$FsDir = "fs"
$OutDir = "out"

($ExtDir, $FsDir, $OutDir) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory $_ | Out-Null
    }    
}

# Download Alpine kernel
Update-DownloadedFile "$AlpineReleasesRoot/netboot/vmlinuz-lts"

# Download Alpine packages
Update-DownloadedFile $AlpinePackageRoot/APKINDEX.tar.gz

Write-Host "Unpacking APK index... " -NoNewline
tar -xf $ExtDir/APKINDEX.tar.gz -C $ExtDir APKINDEX
Write-Host (Format-DataLength (Get-ChildItem $ExtDir/APKINDEX).Length)

Write-Host "Parsing APK index... " -NoNewline
$PackageName = ""
$PackageVersion = ""
$AlpineIndex = Get-Content $ExtDir/APKINDEX | ForEach-Object {
    if ($_ -eq "") {
        @{
            Name = $PackageName
            Version = $PackageVersion
        }
    } elseif ($_ -clike "P:*") {
        $PackageName = ($_ -split ":")[1]
    } elseif ($_ -clike "V:*") {
        $PackageVersion = ($_ -split ":")[1]
    }
} 
Write-Host "$($AlpineIndex.Length) packages"

$PackageFiles = $AlpinePackages | ForEach-Object {
    $Package = $_
    $AlpineIndex | Where-Object { $_.Name -eq $Package }
} | ForEach-Object {
    "$($_.Name)-$($_.Version).apk"
}

$PackageFiles | ForEach-Object {
    Update-DownloadedFile "$AlpinePackageRoot/$_"
}

# Download PowerShell
Update-DownloadedFile $PowerShellUrl

Write-Host

# Prepare filesystem structure
Write-Host "Preparing filesystem directories..."
("bin", "dev", "etc", "opt", "proc", "sys", "tmp") | ForEach-Object {
    New-Item -ItemType Directory -Force $FsDir/$_ | Out-Null
}

# Unpack Alpine packages
$PackageFiles | ForEach-Object {
    Expand-Tgz $_ $FsDir
}

# Unpack .NET package
New-Item -ItemType Directory -Force $FsDir/opt/microsoft/powershell/7 | Out-Null
Expand-Tgz ([System.IO.Path]::GetFileName($PowerShellUrl)) $FsDir/opt/microsoft/powershell/7

# Add custom files
Write-Host "Adding custom files..."
Copy-Item init $FsDir/init
New-Item -ItemType File $FsDir/etc/passwd -ErrorAction Ignore | Out-Null

Write-Host

# Create initramfs
Remove-Item $OutDir/initramfs.cpio -ErrorAction Ignore
Write-Host "Packing initramfs... " -NoNewline
Set-Location $FsDir
sh -c "find . | cpio --quiet -o -H newc > ../$OutDir/initramfs.cpio" | Out-Null
Set-Location ..
Write-Host (Format-DataLength (Get-ChildItem $OutDir/initramfs.cpio).Length)

Write-Host "Compressing initramfs... " -NoNewline
sh -c "gzip < $OutDir/initramfs.cpio > $OutDir/initramfs.cpio.gz"
Write-Host (Format-DataLength (Get-ChildItem $OutDir/initramfs.cpio.gz).Length)

# Copy the kernel
Write-Host "Copying the kernel... " -NoNewline
Copy-Item $ExtDir/vmlinuz-lts $OutDir/vmlinuz-lts
Write-Host (Format-DataLength (Get-ChildItem $OutDir/vmlinuz-lts).Length)
