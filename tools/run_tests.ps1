# Ejecuta la suite de smoke tests en paralelo y resume el resultado.
# Uso:
#   powershell -File tools/run_tests.ps1                  # suite completa
#   powershell -File tools/run_tests.ps1 -Filter "*enemy*" # solo los que coinciden
#   powershell -File tools/run_tests.ps1 -Jobs 4 -NoRetry
# Mejoras (2026-11-27):
# - El filtro solo considera archivos .gd (antes los .uid contaban como fallos).
# - Mide la duracion de cada test y muestra los mas lentos.
# - Los tests que fallan se reintentan UNA vez en serie: con varios Godot en
#   paralelo algunos tests de tiempos (p. ej. level_six) dan falsos fallos. Un
#   test que solo pasa al reintentar se marca como INTERMITENTE.
# - Escribe el informe en tests/last_run.txt.
# Devuelve exit code 1 si algun test falla tambien al reintentar.
param(
    [int]$Jobs = 3,
    [string]$Filter = "*",
    [switch]$NoRetry,
    [string]$Godot = "C:\Users\Usuario\Downloads\Godot_v4.7.2-stable_win64_console.exe"
)
$project = Split-Path -Parent $PSScriptRoot
$pattern = if ($Filter.EndsWith(".gd")) { $Filter } else { "$Filter.gd" }
$tests = @(Get-ChildItem (Join-Path $project "tests") -File | Where-Object { $_.Extension -eq ".gd" -and $_.Name -like $pattern })
if ($tests.Count -eq 0) { Write-Output "No hay tests que coincidan con '$pattern'"; exit 1 }

$runOne = {
    param($g, $p, $n)
    $start = Get-Date
    $o = & $g --headless --path $p --script "res://tests/$n" 2>&1
    [pscustomobject]@{
        Name = $n
        Code = $LASTEXITCODE
        Seconds = [math]::Round(((Get-Date) - $start).TotalSeconds, 1)
        Fails = @($o | Select-String "FALLO|SCRIPT ERROR|Parse Error")
    }
}

$suiteStart = Get-Date
foreach ($t in $tests) {
    while ((Get-Job -State Running).Count -ge $Jobs) { Start-Sleep -Milliseconds 200 }
    Start-Job -Name $t.Name -ArgumentList $Godot, $project, $t.Name -ScriptBlock $runOne | Out-Null
}
Get-Job | Wait-Job | Out-Null
$all = @(Get-Job | Receive-Job)
Get-Job | Remove-Job

$failed = @($all | Where-Object { $_.Code -ne 0 })
$flaky = @()
if (-not $NoRetry -and $failed.Count -gt 0) {
    $still = @()
    foreach ($f in $failed) {
        $again = & $runOne $Godot $project $f.Name
        if ($again.Code -eq 0) { $flaky += $f.Name } else { $still += $again }
    }
    $failed = $still
}

$report = @()
foreach ($f in $failed) { $report += "FAIL $($f.Name)"; $f.Fails | ForEach-Object { $report += "   $_" } }
foreach ($n in $flaky) { $report += "INTERMITENTE $n (fallo en paralelo, paso al reintentar)" }
$report += "Mas lentos:"
$all | Sort-Object Seconds -Descending | Select-Object -First 5 | ForEach-Object { $report += ("   {0,6}s  {1}" -f $_.Seconds, $_.Name) }
$total = [math]::Round(((Get-Date) - $suiteStart).TotalSeconds, 0)
$report += "tests=$($all.Count) fails=$($failed.Count) intermitentes=$($flaky.Count) tiempo=${total}s"
$report | ForEach-Object { Write-Output $_ }
$report | Set-Content -Encoding utf8 (Join-Path $project "tests/last_run.txt")
exit ($(if ($failed.Count -gt 0) { 1 } else { 0 }))
