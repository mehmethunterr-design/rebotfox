$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repositoryRoot

function Invoke-Flutter {
    param([Parameter(Mandatory = $true)][string[]] $Arguments)

    & flutter @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter komutu basarisiz oldu: flutter $($Arguments -join ' ')"
    }
}

function Expand-FirebaseCppSdk {
    param(
        [Parameter(Mandatory = $true)][string] $ArchivePath,
        [Parameter(Mandatory = $true)][string] $DestinationDirectory
    )

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $includePrefix = 'firebase_cpp_sdk_windows/include/'
    $releasePrefix = 'firebase_cpp_sdk_windows/libs/windows/VS2019/MD/x64/Release/'
    $cmakeFile = 'firebase_cpp_sdk_windows/CMakeLists.txt'
    $destinationRoot = [System.IO.Path]::GetFullPath($DestinationDirectory)
    if (-not $destinationRoot.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
        $destinationRoot += [System.IO.Path]::DirectorySeparatorChar
    }

    $archive = [System.IO.Compression.ZipFile]::OpenRead($ArchivePath)
    try {
        foreach ($entry in $archive.Entries) {
            $entryName = $entry.FullName.Replace('\', '/')
            $selected = $entryName.Equals($cmakeFile, [System.StringComparison]::Ordinal) -or
                $entryName.StartsWith($includePrefix, [System.StringComparison]::Ordinal) -or
                $entryName.StartsWith($releasePrefix, [System.StringComparison]::Ordinal)

            if (-not $selected -or $entryName.EndsWith('/')) {
                continue
            }

            $relativePath = $entryName.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
            $destinationPath = [System.IO.Path]::GetFullPath(
                (Join-Path $DestinationDirectory $relativePath)
            )

            if (-not $destinationPath.StartsWith(
                $destinationRoot,
                [System.StringComparison]::OrdinalIgnoreCase
            )) {
                throw "Firebase ZIP gecersiz bir dosya yolu iceriyor: $entryName"
            }

            $parentDirectory = Split-Path -Parent $destinationPath
            [System.IO.Directory]::CreateDirectory($parentDirectory) | Out-Null

            $inputStream = $null
            $outputStream = $null
            try {
                $inputStream = $entry.Open()
                $outputStream = [System.IO.File]::Create($destinationPath)
                $inputStream.CopyTo($outputStream)
            } finally {
                if ($outputStream) {
                    $outputStream.Dispose()
                }
                if ($inputStream) {
                    $inputStream.Dispose()
                }
            }
        }
    } finally {
        $archive.Dispose()
    }
}

function Get-FirebaseCppSdk {
    $sdkVersion = '13.9.0'
    $expectedArchiveBytes = 958942848
    $cacheRoot = Join-Path $env:LOCALAPPDATA 'Rebotfox'
    $cacheDirectory = Join-Path $cacheRoot "firebase_cpp_sdk_$sdkVersion"
    $archiveName = "firebase_cpp_sdk_windows_$sdkVersion.zip"
    $archivePath = Join-Path $cacheRoot $archiveName
    $legacyArchivePath = Join-Path $cacheDirectory $archiveName
    $sdkDirectory = Join-Path $cacheDirectory 'firebase_cpp_sdk_windows'
    $versionHeader = Join-Path $sdkDirectory 'include\firebase\version.h'
    $cmakeFile = Join-Path $sdkDirectory 'CMakeLists.txt'
    $releaseDirectory = Join-Path $sdkDirectory 'libs\windows\VS2019\MD\x64\Release'
    $requiredFiles = @(
        $versionHeader,
        $cmakeFile,
        (Join-Path $releaseDirectory 'firebase_app.lib'),
        (Join-Path $releaseDirectory 'firebase_auth.lib'),
        (Join-Path $releaseDirectory 'firebase_firestore.lib'),
        (Join-Path $releaseDirectory 'firebase_storage.lib')
    )
    $cacheReady = ($requiredFiles | Where-Object { -not (Test-Path $_) }).Count -eq 0

    if ($cacheReady) {
        Write-Host "Firebase Windows SDK onbellekten kullanilacak: $sdkDirectory" -ForegroundColor DarkGray
        return $sdkDirectory
    }

    [System.IO.Directory]::CreateDirectory($cacheRoot) | Out-Null

    if (
        -not (Test-Path $archivePath) -and
        (Test-Path $legacyArchivePath) -and
        (Get-Item $legacyArchivePath).Length -eq $expectedArchiveBytes
    ) {
        [System.IO.File]::Move($legacyArchivePath, $archivePath)
    }

    if (Test-Path $cacheDirectory) {
        [System.IO.Directory]::Delete($cacheDirectory, $true)
    }
    [System.IO.Directory]::CreateDirectory($cacheDirectory) | Out-Null

    if (
        (Test-Path $archivePath) -and
        (Get-Item $archivePath).Length -ne $expectedArchiveBytes
    ) {
        [System.IO.File]::Delete($archivePath)
    }

    $downloadUrl = "https://dl.google.com/firebase/sdk/cpp/firebase_cpp_sdk_windows_$sdkVersion.zip"
    if (-not (Test-Path $archivePath)) {
        Write-Host ''
        Write-Host 'Firebase Windows SDK indiriliyor. Bu islem birkac dakika surebilir...' -ForegroundColor Cyan

        try {
            Import-Module BitsTransfer -ErrorAction Stop
            Start-BitsTransfer -Source $downloadUrl -Destination $archivePath -ErrorAction Stop
        } catch {
            if (Test-Path $archivePath) {
                [System.IO.File]::Delete($archivePath)
            }
            Write-Host 'BITS kullanilamadi; normal indirme yontemi deneniyor...' -ForegroundColor Yellow
            Invoke-WebRequest -Uri $downloadUrl -OutFile $archivePath -UseBasicParsing
        }
    } else {
        Write-Host 'Daha once indirilen Firebase ZIP kullanilacak.' -ForegroundColor DarkGray
    }

    if ((Get-Item $archivePath).Length -ne $expectedArchiveBytes) {
        throw 'Firebase Windows SDK indirmesi eksik kaldi. Betigi yeniden calistir.'
    }

    Write-Host 'Firebase Windows SDK icinden gerekli x64 dosyalari cikariliyor...' -ForegroundColor Cyan
    try {
        Expand-FirebaseCppSdk -ArchivePath $archivePath -DestinationDirectory $cacheDirectory
    } catch {
        throw "Firebase Windows SDK cikarilamadi. C surucusunde en az 5 GB bos alan birak. Ayrinti: $($_.Exception.Message)"
    }

    $missingFiles = $requiredFiles | Where-Object { -not (Test-Path $_) }
    if ($missingFiles.Count -gt 0) {
        throw "Firebase Windows SDK eksik cikarildi: $($missingFiles -join ', ')"
    }

    [System.IO.File]::Delete($archivePath)
    return $sdkDirectory
}

Write-Host ''
Write-Host 'Rebotfox Windows EXE hazirlaniyor...' -ForegroundColor Cyan
Write-Host ''

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'Flutter bulunamadi. Flutter kurulumunu ve PATH ayarini kontrol et.'
}

$vsWhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
$vsInstaller = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\setup.exe'
if (-not (Test-Path $vsWhere)) {
    Write-Host 'Visual Studio bulunamadi.' -ForegroundColor Yellow
    Write-Host 'Visual Studio Community kurulumunda "Desktop development with C++" is yukunu sec.'
    Start-Process 'https://visualstudio.microsoft.com/vs/community/'
    throw 'Visual Studio kurulduktan sonra BUILD_WINDOWS_EXE.bat dosyasini yeniden calistir.'
}

$visualStudioPath = & $vsWhere `
    -latest `
    -products '*' `
    -requires Microsoft.VisualStudio.Workload.NativeDesktop `
    -property installationPath

if (-not $visualStudioPath) {
    Write-Host 'Desktop development with C++ is yuku eksik.' -ForegroundColor Yellow
    if (Test-Path $vsInstaller) {
        Start-Process $vsInstaller
    }
    throw 'Visual Studio Installer uzerinden Desktop development with C++ is yukunu ekle.'
}

Invoke-Flutter @('config', '--enable-windows-desktop')
Invoke-Flutter @(
    'create',
    '--platforms=windows',
    '--org',
    'com.rebotfox',
    '--project-name',
    'rebotfox',
    '.'
)

$runnerDirectory = Join-Path $repositoryRoot 'windows\runner'
$iconSource = Join-Path $repositoryRoot 'assets\images\rebotfox_app_icon.png'
$iconDestination = Join-Path $runnerDirectory 'resources\app_icon.ico'

try {
    Add-Type -AssemblyName System.Drawing
    Add-Type @'
using System;
using System.Runtime.InteropServices;

public static class RebotfoxNativeMethods
{
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern bool DestroyIcon(IntPtr handle);
}
'@

    $bitmap = [System.Drawing.Bitmap]::FromFile($iconSource)
    $iconHandle = $bitmap.GetHicon()
    $icon = [System.Drawing.Icon]::FromHandle($iconHandle)
    $iconStream = [System.IO.File]::Create($iconDestination)
    $icon.Save($iconStream)
    $iconStream.Dispose()
    $icon.Dispose()
    $bitmap.Dispose()
    [RebotfoxNativeMethods]::DestroyIcon($iconHandle) | Out-Null
} catch {
    Write-Host 'Rebotfox simgesi donusturulemedi; varsayilan Windows simgesi kullanilacak.' -ForegroundColor Yellow
}

$mainCppPath = Join-Path $runnerDirectory 'main.cpp'
$mainCpp = [System.IO.File]::ReadAllText($mainCppPath)
$mainCpp = $mainCpp.Replace('L"rebotfox"', 'L"Rebotfox Teknik Servis"')
$utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($mainCppPath, $mainCpp, $utf8WithoutBom)

$env:FIREBASE_CPP_SDK_DIR = Get-FirebaseCppSdk
Write-Host "Firebase SDK hazir: $env:FIREBASE_CPP_SDK_DIR" -ForegroundColor Green

Invoke-Flutter @('clean')
Invoke-Flutter @('pub', 'get')
Invoke-Flutter @('analyze', '--no-fatal-infos', '--no-fatal-warnings')
Invoke-Flutter @('build', 'windows', '--release')

$releaseCandidates = @(
    (Join-Path $repositoryRoot 'build\windows\x64\runner\Release'),
    (Join-Path $repositoryRoot 'build\windows\runner\Release')
)
$releaseDirectory = $releaseCandidates |
    Where-Object { Test-Path $_ } |
    Select-Object -First 1

if (-not $releaseDirectory) {
    throw 'Windows Release klasoru bulunamadi.'
}

$distDirectory = Join-Path $repositoryRoot 'dist'
[System.IO.Directory]::CreateDirectory($distDirectory) | Out-Null
$zipPath = Join-Path $distDirectory 'Rebotfox-Windows-x64.zip'
Compress-Archive -Path (Join-Path $releaseDirectory '*') -DestinationPath $zipPath -Force

$exePath = Join-Path $releaseDirectory 'rebotfox.exe'
if (-not (Test-Path $exePath)) {
    throw 'rebotfox.exe derleme sonrasinda bulunamadi.'
}

Write-Host ''
Write-Host 'Derleme tamamlandi.' -ForegroundColor Green
Write-Host "EXE: $exePath"
Write-Host "Tasinabilir paket: $zipPath"

Start-Process explorer.exe -ArgumentList "/select,`"$exePath`""
