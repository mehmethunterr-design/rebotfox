$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repositoryRoot

function Invoke-Flutter {
    param([Parameter(Mandatory = $true)][string[]] $Arguments)

    & flutter @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter komutu başarısız oldu: flutter $($Arguments -join ' ')"
    }
}

function Get-FirebaseCppSdk {
    $sdkVersion = '13.9.0'
    $cacheRoot = Join-Path $env:LOCALAPPDATA 'Rebotfox'
    $cacheDirectory = Join-Path $cacheRoot "firebase_cpp_sdk_$sdkVersion"
    $sdkDirectory = Join-Path $cacheDirectory 'firebase_cpp_sdk_windows'
    $versionHeader = Join-Path $sdkDirectory 'include\firebase\version.h'

    if (Test-Path $versionHeader) {
        Write-Host "Firebase Windows SDK önbellekten kullanılacak: $sdkDirectory" -ForegroundColor DarkGray
        return $sdkDirectory
    }

    if (Test-Path $cacheDirectory) {
        [System.IO.Directory]::Delete($cacheDirectory, $true)
    }
    [System.IO.Directory]::CreateDirectory($cacheDirectory) | Out-Null

    $archivePath = Join-Path $cacheDirectory "firebase_cpp_sdk_windows_$sdkVersion.zip"
    $downloadUrl = "https://dl.google.com/firebase/sdk/cpp/firebase_cpp_sdk_windows_$sdkVersion.zip"

    Write-Host ''
    Write-Host 'Firebase Windows SDK indiriliyor. Bu işlem internet hızına göre birkaç dakika sürebilir...' -ForegroundColor Cyan

    try {
        Import-Module BitsTransfer -ErrorAction Stop
        Start-BitsTransfer -Source $downloadUrl -Destination $archivePath -ErrorAction Stop
    } catch {
        Write-Host 'BITS kullanılamadı; normal indirme yöntemi deneniyor...' -ForegroundColor Yellow
        Invoke-WebRequest -Uri $downloadUrl -OutFile $archivePath -UseBasicParsing
    }

    Write-Host 'Firebase Windows SDK çıkarılıyor...' -ForegroundColor Cyan
    try {
        Expand-Archive -LiteralPath $archivePath -DestinationPath $cacheDirectory -Force
    } catch {
        throw "Firebase Windows SDK arşivi çıkarılamadı. Diskte en az 6 GB boş alan olduğundan emin ol. Ayrıntı: $($_.Exception.Message)"
    }

    if (-not (Test-Path $versionHeader)) {
        throw "Firebase Windows SDK eksik çıkarıldı: $versionHeader"
    }

    [System.IO.File]::Delete($archivePath)
    return $sdkDirectory
}

Write-Host ''
Write-Host 'Rebotfox Windows EXE hazırlanıyor...' -ForegroundColor Cyan
Write-Host ''

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'Flutter bulunamadı. Flutter kurulumunu ve PATH ayarını kontrol et.'
}

$vsWhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
$vsInstaller = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\setup.exe'
if (-not (Test-Path $vsWhere)) {
    Write-Host 'Visual Studio bulunamadı.' -ForegroundColor Yellow
    Write-Host 'Visual Studio Community kurulumunda "Desktop development with C++" iş yükünü seç.'
    Start-Process 'https://visualstudio.microsoft.com/vs/community/'
    throw 'Visual Studio kurulduktan sonra BUILD_WINDOWS_EXE.bat dosyasını yeniden çalıştır.'
}

$visualStudioPath = & $vsWhere `
    -latest `
    -products '*' `
    -requires Microsoft.VisualStudio.Workload.NativeDesktop `
    -property installationPath

if (-not $visualStudioPath) {
    Write-Host 'Desktop development with C++ iş yükü eksik.' -ForegroundColor Yellow
    if (Test-Path $vsInstaller) {
        Start-Process $vsInstaller
    }
    throw 'Visual Studio Installer üzerinden Desktop development with C++ iş yükünü ekle.'
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
    Write-Host 'Rebotfox simgesi dönüştürülemedi; varsayılan Windows simgesi kullanılacak.' -ForegroundColor Yellow
}

$mainCppPath = Join-Path $runnerDirectory 'main.cpp'
$mainCpp = [System.IO.File]::ReadAllText($mainCppPath)
$mainCpp = $mainCpp.Replace('L"rebotfox"', 'L"Rebotfox Teknik Servis"')
$utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($mainCppPath, $mainCpp, $utf8WithoutBom)

$env:FIREBASE_CPP_SDK_DIR = Get-FirebaseCppSdk
Write-Host "Firebase SDK hazır: $env:FIREBASE_CPP_SDK_DIR" -ForegroundColor Green

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
    throw 'Windows Release klasörü bulunamadı.'
}

$distDirectory = Join-Path $repositoryRoot 'dist'
[System.IO.Directory]::CreateDirectory($distDirectory) | Out-Null
$zipPath = Join-Path $distDirectory 'Rebotfox-Windows-x64.zip'
Compress-Archive -Path (Join-Path $releaseDirectory '*') -DestinationPath $zipPath -Force

$exePath = Join-Path $releaseDirectory 'rebotfox.exe'
if (-not (Test-Path $exePath)) {
    throw 'rebotfox.exe derleme sonrasında bulunamadı.'
}

Write-Host ''
Write-Host 'Derleme tamamlandı.' -ForegroundColor Green
Write-Host "EXE: $exePath"
Write-Host "Taşınabilir paket: $zipPath"

Start-Process explorer.exe -ArgumentList "/select,`"$exePath`""
