# instruction with the reference model (tools\iss.py).
# Usage: .\run_tests.ps1             all rv32ui tests
#        .\run_tests.ps1 add         just add.S (also prints the trace)
param([string]$Name)

. (Join-Path $PSScriptRoot 'tools\core_sim.ps1')

$tests = Join-Path $Root 'tests\riscv-tests'
if (-not (Test-Path $tests)) {
    Write-Host "Cloning riscv-tests into tests\riscv-tests ..."
    git clone --depth 1 https://github.com/riscv-software-src/riscv-tests.git $tests
    if ($LASTEXITCODE -ne 0) { exit 1 }
}

if (-not (Build-CoreTb)) { exit 1 }

# fence_i needs self-modifying code; ma_data needs misaligned access.
$skip = @('fence_i', 'ma_data')
$include = @('-I', (Join-Path $Root 'tests\env'), '-I', (Join-Path $tests 'isa\macros\scalar'))

$sources = @(Get-ChildItem (Join-Path $tests 'isa\rv32ui') -Filter *.S |
    Where-Object { $skip -notcontains $_.BaseName } | Sort-Object Name)
if ($Name) { $sources = @($sources | Where-Object { $_.BaseName -eq $Name }) }
if ($sources.Count -eq 0) { Write-Host "No test named '$Name'" -ForegroundColor Red; exit 1 }

$failed = 0
foreach ($s in $sources) {
    $hex = Build-Hex $s.FullName (Join-Path $Build 'rv32ui') $include
    if (-not $hex) { Write-Host "FAIL   $($s.BaseName): does not assemble" -ForegroundColor Red; $failed++; continue }
    $r = Invoke-Program $hex -ShowTrace:([bool]$Name)
    if (-not (Write-Result $s.BaseName $r)) { $failed++ }
}

Write-Host ""
Write-Host "$($sources.Count - $failed) / $($sources.Count) passed" -ForegroundColor $(if ($failed) { 'Red' } else { 'Green' })
exit $failed
