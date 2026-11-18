param()

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

$jar = Join-Path $sdk "bin\monkeybrains.jar"
$outDir = Join-Path $root "bin"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$iq = Join-Path $outDir "MarathonFuel.iq"

Write-Host "SDK  $sdk"
Write-Host "Java $javaExe"
Write-Host "Packaging store IQ for all products in manifest.xml..."

& $javaExe -jar $jar -e -r -o $iq -f (Join-Path $root "monkey.jungle") -y $key -w -l 0
if ($LASTEXITCODE -ne 0) {
    throw "Store package failed"
}
if (-not (Test-Path $iq)) {
    throw "Compiler reported success but $iq was not created"
}

$storeDir = Join-Path $root "store"
New-Item -ItemType Directory -Force -Path $storeDir | Out-Null
$storeIq = Join-Path $storeDir "MarathonFuel.iq"
Copy-Item -Force $iq $storeIq

$info = Get-Item $storeIq
Write-Host ("Ready {0} ({1:N0} bytes)" -f $info.FullName, $info.Length)
Write-Host "Upload at https://apps.garmin.com/developer"
