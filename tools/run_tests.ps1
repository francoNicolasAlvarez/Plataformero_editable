# Ejecuta toda la suite de smoke tests en paralelo y resume el resultado.
# Uso: powershell -File tools/run_tests.ps1 [-Jobs 4] [-Filter "player*"]
# Devuelve exit code 1 si algun test falla. Los tests que dependen de tiempos
# (p. ej. level_six_smoke_test) pueden dar falsos fallos con demasiados jobs.
param(
    [int]$Jobs = 3,
    [string]$Filter = "*.gd",
    [string]$Godot = "C:\Users\Usuario\Downloads\Godot_v4.7.2-stable_win64_console.exe"
)
$project = Split-Path -Parent $PSScriptRoot
$tests = Get-ChildItem (Join-Path $project "tests") -Filter $Filter
$running = @()
$results = @()
function Collect($job) {
    $out = Receive-Job $job -Wait
    $code = $job.ChildJobs[0].Output | Select-Object -Last 1
    Remove-Job $job
    return $out
}
foreach ($t in $tests) {
    while ((Get-Job -State Running).Count -ge $Jobs) { Start-Sleep -Milliseconds 300 }
    Start-Job -Name $t.Name -ArgumentList $Godot, $project, $t.Name -ScriptBlock {
        param($g, $p, $n)
        $o = & $g --headless --path $p --script "res://tests/$n" 2>&1
        [pscustomobject]@{ Name = $n; Code = $LASTEXITCODE; Fails = @($o | Select-String "FALLO|SCRIPT ERROR") }
    } | Out-Null
}
Get-Job | Wait-Job | Out-Null
$all = Get-Job | Receive-Job
Get-Job | Remove-Job
$failed = @($all | Where-Object { $_.Code -ne 0 })
foreach ($f in $failed) { Write-Output "FAIL $($f.Name)"; $f.Fails | ForEach-Object { Write-Output "   $_" } }
Write-Output "tests=$($all.Count) fails=$($failed.Count)"
exit ($(if ($failed.Count -gt 0) { 1 } else { 0 }))
