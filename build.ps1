param(
    [string]$Device = "fr945"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

function Find-Sdk {
    if ($env:GARMIN_SDK -and (Test-Path (Join-Path $env:GARMIN_SDK "bin\monkeybrains.jar"))) {
        return $env:GARMIN_SDK
    }
    $candidates = @(
        "$env:LOCALAPPDATA\connectiq-sdk",
        "$env:APPDATA\Garmin\ConnectIQ\Sdks",
        "$env:USERPROFILE\AppData\Roaming\Garmin\ConnectIQ\Sdks"
    )
    foreach ($dir in $candidates) {
        if (Test-Path (Join-Path $dir "bin\monkeybrains.jar")) { return $dir }
        if (Test-Path $dir) {
            $found = Get-ChildItem $dir -Directory -ErrorAction SilentlyContinue |
                Where-Object { Test-Path (Join-Path $_.FullName "bin\monkeybrains.jar") } |
                Sort-Object Name -Descending |
                Select-Object -First 1
            if ($found) { return $found.FullName }
        }
    }
    return $null
}

function Find-Java {
    $paths = @()
    if ($env:JAVA_HOME) { $paths += (Join-Path $env:JAVA_HOME "bin\java.exe") }
    $paths += "$env:LOCALAPPDATA\jdk\jdk-17.0.21+9\bin\java.exe"
    Get-ChildItem "$env:LOCALAPPDATA\jdk" -Recurse -Filter java.exe -ErrorAction SilentlyContinue |
        ForEach-Object { $paths += $_.FullName }
    $cmd = Get-Command java -ErrorAction SilentlyContinue
    if ($cmd) { $paths += $cmd.Source }
    foreach ($p in $paths) {
        if ($p -and (Test-Path $p)) { return $p }
    }
    return $null
}

$sdk = Find-Sdk
if (-not $sdk) {
    throw "Connect IQ SDK not found. Set GARMIN_SDK or install SDK Manager and download an SDK."
}

$javaExe = Find-Java
if (-not $javaExe) {
    throw "Java is not installed. Install a JDK 17+ and rerun."
}

$key = Join-Path $root "developer_key.der"
if (-not (Test-Path $key)) {
    throw "Missing developer_key.der in the project folder."
}

$devicesDir = Join-Path $env:APPDATA "Garmin\ConnectIQ\Devices\$Device"
if (-not (Test-Path $devicesDir)) {
    throw @"
Forerunner 945 device files are not installed.
1. Unzip Connect IQ SDK Manager (see README).
2. Sign in with a Garmin account.
3. Download SDK 9.3.0 if needed, then download the Forerunner 945 device.
4. Rerun .\build.ps1
Expected folder: $devicesDir
"@
}

$jar = Join-Path $sdk "bin\monkeybrains.jar"
$outDir = Join-Path $root "bin"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$prg = Join-Path $outDir "MarathonFuel.prg"

Write-Host "SDK    $sdk"
Write-Host "Java   $javaExe"
Write-Host "Device $Device"

& $javaExe -jar $jar -o $prg -f (Join-Path $root "monkey.jungle") -y $key -d $Device -w -l 0
if ($LASTEXITCODE -ne 0) {
    throw "Compile failed"
}
Write-Host "Built $prg"
