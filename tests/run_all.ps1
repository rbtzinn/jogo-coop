param(
    [string]$GodotPath = 'C:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe',
    [string]$LogDirectory = ''
)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
if (-not $LogDirectory) { $LogDirectory = Join-Path $taskRoot 'build\qa\suite' }
New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
$taskResults = [System.Collections.Generic.List[object]]::new()

function Start-GameTest([string]$name, [string[]]$gameArguments) {
    $outPath = Join-Path $LogDirectory ($name + '.log')
    $errPath = Join-Path $LogDirectory ($name + '.err.log')
    $process = Start-Process -FilePath $GodotPath -ArgumentList $gameArguments -WorkingDirectory $taskRoot -WindowStyle Hidden -RedirectStandardOutput $outPath -RedirectStandardError $errPath -PassThru
    return @{ Name=$name; Process=$process; Out=$outPath; Err=$errPath; Started=[datetime]::UtcNow }
}

function Finish-GameTest($test) {
    while (-not $test.Process.WaitForExit(1000)) {
        if (([datetime]::UtcNow - $test.Started).TotalSeconds -gt 1300) {
            Stop-Process -Id $test.Process.Id -Force
            throw ('Timeout: ' + $test.Name)
        }
    }
    $test.Process.Refresh()
    $lines = @(Get-Content -LiteralPath $test.Out) + @(Get-Content -LiteralPath $test.Err)
    $errors = @($lines | Where-Object { $_ -match 'SCRIPT ERROR|^ERROR:|^FAIL\b|\] FAIL\b' })
    $row = [pscustomobject]@{ Test=$test.Name; ExitCode=$test.Process.ExitCode; Errors=$errors.Count; Passed=($test.Process.ExitCode -eq 0 -and $errors.Count -eq 0) }
    $taskResults.Add($row)
    Write-Output ('{0}: exit={1}, errors={2}, passed={3}' -f $row.Test, $row.ExitCode, $row.Errors, $row.Passed)
    if ($errors.Count) { $errors | Select-Object -First 8 | Write-Output }
}

$import = Start-GameTest 'import' @('--headless','--path',$taskRoot,'--import')
Finish-GameTest $import
if (-not $taskResults[0].Passed) { exit 1 }
$offline = Get-ChildItem -LiteralPath $PSScriptRoot -Filter 'test_*.tscn' | Where-Object { $_.BaseName -notin 'test_online' }
foreach ($scene in $offline) {
    $test = Start-GameTest $scene.BaseName @('--headless','--path',$taskRoot,'--fixed-fps','60',('res://tests/' + $scene.Name))
    Finish-GameTest $test
}
$onlineScenes = @('test_online')
foreach ($scene in $onlineScenes) {
    foreach ($network in @('normal','ruim')) {
        $netArgs = if ($network -eq 'ruim') { @('ruim') } else { @() }
        $hostTest = Start-GameTest ($scene + '_' + $network + '_host') (@('--headless','--path',$taskRoot,('res://tests/' + $scene + '.tscn'),'--','host') + $netArgs)
        $clientTest = Start-GameTest ($scene + '_' + $network + '_client') (@('--headless','--path',$taskRoot,('res://tests/' + $scene + '.tscn'),'--','client') + $netArgs)
        Finish-GameTest $clientTest
        Finish-GameTest $hostTest
    }
}
$taskResults | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $LogDirectory 'summary.json') -Encoding utf8
if (@($taskResults | Where-Object { -not $_.Passed }).Count) { exit 1 }
exit 0
