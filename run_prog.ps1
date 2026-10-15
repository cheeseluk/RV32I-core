# Build a program from sw\ (assembly) or sw\c\ (C), run it on the core, and
# check it against the reference model (tools\iss.py).
# Usage: .\run_prog.ps1 first        sw\first.S, printing the trace
#        .\run_prog.ps1 queens       sw\c\queens.c (C traces are too long to print)
#        .\run_prog.ps1              every program, one line each
param([string]$Name)

. (Join-Path $PSScriptRoot 'tools\core_sim.ps1')

if (-not (Build-CoreTb)) { exit 1 }

# crt0.S is startup code linked into every C program, not a program itself.
$all = @(Get-ChildItem (Join-Path $Root 'sw') -Filter *.S | Sort-Object Name) +
       @(Get-ChildItem (Join-Path $Root 'sw\c') -Filter *.c | Sort-Object Name)

$programs = if ($Name) {
    $n = [IO.Path]::GetFileNameWithoutExtension($Name)
    @($all | Where-Object { $_.BaseName -eq $n })
} else { $all }
if ($programs.Count -eq 0) { Write-Host "No program named '$Name' in sw\ or sw\c\" -ForegroundColor Red; exit 1 }

$failed = 0
foreach ($p in $programs) {
    $isC = $p.Extension -eq '.c'
    $hex = Build-Hex $p.FullName (Join-Path $Build 'sw')
    if (-not $hex) { Write-Host "FAIL   $($p.BaseName): does not build" -ForegroundColor Red; $failed++; continue }
    # C programs run for ~10^6 instructions; assembly tests for a few hundred.
    $max = if ($isC) { 5000000 } else { 100000 }
    $r = Invoke-Program $hex -ShowTrace:([bool]$Name -and -not $isC) -MaxCycles $max
    if (-not (Write-Result $p.BaseName $r)) { $failed++ }
}

if ($programs.Count -gt 1) {
    Write-Host ""
    Write-Host "$($programs.Count - $failed) / $($programs.Count) passed"
}
exit $failed
