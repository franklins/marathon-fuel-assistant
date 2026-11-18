param(
    [switch]$SkipSimulator
)

$ErrorActionPreference = "Continue"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$env:GARMIN_SDK = if ($env:GARMIN_SDK) { $env:GARMIN_SDK } else { "$env:LOCALAPPDATA\connectiq-sdk" }
$java = "$env:LOCALAPPDATA\jdk\jdk-17.0.21+9\bin\java.exe"
$jar = Join-Path $env:GARMIN_SDK "bin\monkeybrains.jar"
$key = Join-Path $root "developer_key.der"
$jungle = Join-Path $root "monkey.jungle"
$monkeydo = Join-Path $env:GARMIN_SDK "bin\monkeydo.bat"
$sim = Join-Path $env:GARMIN_SDK "bin\simulator.exe"
$outDir = Join-Path $root "bin"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$devices = @(
    @{ id = "fr245"; name = "Forerunner 245" },
    @{ id = "fr255"; name = "Forerunner 255" },
    @{ id = "fr265"; name = "Forerunner 265" },
    @{ id = "fr745"; name = "Forerunner 745" },
    @{ id = "fr945"; name = "Forerunner 945" },
    @{ id = "fr945lte"; name = "Forerunner 945 LTE" },
    @{ id = "fr955"; name = "Forerunner 955" },
    @{ id = "fr965"; name = "Forerunner 965" },
    @{ id = "fr970"; name = "Forerunner 970" },
    @{ id = "fenix6pro"; name = "Fenix 6 Pro" },
    @{ id = "fenix7"; name = "Fenix 7" },
    @{ id = "fenix7pro"; name = "Fenix 7 Pro" },
    @{ id = "fenix7x"; name = "Fenix 7X" },
    @{ id = "fenix847mm"; name = "Fenix 8 47mm" },
    @{ id = "fenix947mm"; name = "Fenix 9 47mm" },
    @{ id = "epix2"; name = "Epix Gen 2" },
    @{ id = "epix2pro47mm"; name = "Epix Pro 47mm" },
    @{ id = "venu2"; name = "Venu 2" },
    @{ id = "venu3"; name = "Venu 3" },
    @{ id = "vivoactive4"; name = "Vivoactive 4" },
    @{ id = "vivoactive5"; name = "Vivoactive 5" },
    @{ id = "instinct2"; name = "Instinct 2" }
)

$results = @()

Write-Host "=== COMPILE ==="
foreach ($d in $devices) {
    $prg = Join-Path $outDir ("MarathonFuel-" + $d.id + ".prg")
    $err = Join-Path $outDir ("compile-" + $d.id + ".log")
    & $java -jar $jar -o $prg -f $jungle -y $key -d $d.id -l 0 2>$err
    $ok = ($LASTEXITCODE -eq 0) -and (Test-Path $prg)
    $warn = ""
    if (Test-Path $err) { $warn = (Get-Content $err -Raw) }
    $results += [pscustomobject]@{ Device = $d.name; Id = $d.id; Compile = $(if ($ok) { "PASS" } else { "FAIL" }); Sim = ""; Detail = $warn.Trim() }
    if ($ok) { Write-Host "COMPILE PASS $($d.id)" } else { Write-Host "COMPILE FAIL $($d.id)"; Write-Host $warn }
}

Write-Host "=== UNIT TESTS (fr945) ==="
$testPrg = Join-Path $outDir "MarathonFuel-fr945-tests.prg"
$testLog = Join-Path $outDir "unit-tests.log"
& $java -jar $jar -o $testPrg -f $jungle -y $key -d fr945 -l 0 -t 2>$testLog
$unitCompile = $LASTEXITCODE -eq 0

if (-not $SkipSimulator) {
    if (-not (Get-Process simulator -ErrorAction SilentlyContinue)) {
        Start-Process $sim
        Start-Sleep -Seconds 8
    }

    if ($unitCompile) {
        Write-Host "Running monkey unit tests..."
        $unitOut = & $monkeydo $testPrg fr945 /t 2>&1 | Out-String
        Set-Content -Path (Join-Path $outDir "unit-tests-run.log") -Value $unitOut
        Write-Host $unitOut
    }

    Write-Host "=== SIMULATOR LOAD ==="
    foreach ($row in $results) {
        if ($row.Compile -ne "PASS") { $row.Sim = "SKIP"; continue }
        $prg = Join-Path $outDir ("MarathonFuel-" + $row.Id + ".prg")
        $out = & $monkeydo $prg $row.Id 2>&1 | Out-String
        $pass = $LASTEXITCODE -eq 0 -and $out -notmatch "(?i)error|failed|exception"
        $row.Sim = if ($pass) { "PASS" } else { "FAIL" }
        $row.Detail = ($row.Detail + "`n" + $out).Trim()
        Write-Host "SIM $($row.Sim) $($row.Id)"
        if (-not $pass) { Write-Host $out }
        Start-Sleep -Milliseconds 800
    }
}

$results | Format-Table Device, Id, Compile, Sim -AutoSize
$results | ConvertTo-Csv -NoTypeInformation | Set-Content (Join-Path $outDir "device-test-results.csv")
$fail = @($results | Where-Object { $_.Compile -eq "FAIL" -or $_.Sim -eq "FAIL" }).Count
Write-Host "Failures: $fail / $($results.Count)"
if ($fail -gt 0) { exit 1 }
