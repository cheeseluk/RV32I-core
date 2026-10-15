# Compile and run the testbench for a module with Icarus Verilog.
# Usage: .\sim.ps1 alu.sv          (or alu_tb.sv; either finds alu_tb.sv)
#        .\sim.ps1 alu.sv -Wave    (also opens the waveform in GTKWave)
param(
    [Parameter(Mandatory)][string]$File,
    [switch]$Wave
)

$root  = $PSScriptRoot
$name  = [IO.Path]::GetFileNameWithoutExtension($File)
$tb    = if ($name -like '*_tb') { $name } else { "${name}_tb" }
$tbSrc = Join-Path $root "tb\$tb.sv"
if (-not (Test-Path $tbSrc)) {
    Write-Host "No testbench found: $tb.sv" -ForegroundColor Red
    exit 1
}

$build = Join-Path $root 'build'
New-Item -ItemType Directory -Force $build | Out-Null

# Every design file in rtl/, plus the one testbench.
# Packages (*_pkg.sv) go first so the modules that import them compile.
$sources = @(Get-ChildItem (Join-Path $root 'rtl') -Filter *.sv |
    Sort-Object { $_.BaseName -notlike '*_pkg' }, Name |
    ForEach-Object { $_.FullName })

iverilog -g2012 -s $tb -o "$build\$tb.vvp" $sources $tbSrc
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Run from build/ so the .vcd lands there too.
Push-Location $build
try     { vvp -n "$tb.vvp" }
finally { Pop-Location }

if ($Wave) { Start-Process gtkwave "$build\$tb.vcd" }
