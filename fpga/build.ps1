# Run a program on the Nexys A7: simulate the board, build a bitstream, or load it.
# Usage: .\fpga\build.ps1 leds -Sim                 simulate nexys_top running fpga\sw\leds.S
#        .\fpga\build.ps1 leds -Sim -Sw a5a5        ...with the switches set to a5a5
#        .\fpga\build.ps1 queens                    build build\fpga\nexys_top.bit with Vivado
#        .\fpga\build.ps1 queens -Program           ...and load it onto the board over USB
#        .\fpga\build.ps1 leds -Part xc7a50ticsg324-1L   for the Nexys A7-50T
# Programs are looked up in fpga\sw\, sw\ and sw\c\.
param(
    [Parameter(Mandatory)][string]$Name,
    [switch]$Sim,
    [switch]$Program,
    [string]$Sw = '0',
    [string]$Part = 'xc7a100tcsg324-1'
)

. (Join-Path $PSScriptRoot '..\tools\core_sim.ps1')

$MemWords = 4096    # nexys_top MEM_WORDS
$Out = Join-Path $Build 'fpga'

$n = [IO.Path]::GetFileNameWithoutExtension($Name)
$src = @(Get-ChildItem (Join-Path $Root 'fpga\sw') -Filter *.S) +
       @(Get-ChildItem (Join-Path $Root 'sw') -Filter *.S) +
       @(Get-ChildItem (Join-Path $Root 'sw\c') -Filter *.c) |
    Where-Object { $_.BaseName -eq $n } | Select-Object -First 1
if (-not $src) { Write-Host "No program named '$Name' in fpga\sw\, sw\ or sw\c\" -ForegroundColor Red; exit 1 }

$hex = Build-Hex $src.FullName $Out
if (-not $hex) { Write-Host "$($src.Name) does not build" -ForegroundColor Red; exit 1 }
$words = @(Get-Content $hex).Count
if ($words -gt $MemWords) { Write-Host "$($src.Name) is $words words; the board has $MemWords" -ForegroundColor Red; exit 1 }

if ($Sim) {
    $sources = @(Get-ChildItem (Join-Path $Root 'rtl') -Filter *.sv |
        Sort-Object { $_.BaseName -notlike '*_pkg' }, Name |
        ForEach-Object { $_.FullName }) +
        @('sevenseg.sv', 'nexys_top.sv', 'nexys_top_tb.sv' | ForEach-Object { Join-Path $PSScriptRoot $_ })
    $vvp = Join-Path $Out 'nexys_top_tb.vvp'
    $out = & iverilog -g2012 -s nexys_top_tb -o $vvp $sources 2>&1
    $out | Where-Object { "$_" -notmatch 'sorry: constant selects' } | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -ne 0) { exit 1 }
    & vvp -n $vvp "+hex=$hex" "+sw=$Sw" | Where-Object { $_ -notmatch '\$finish called' }
    exit 0
}

if (-not (Get-Command vivado -ErrorAction SilentlyContinue)) {
    Write-Host "vivado is not on the PATH. Add <Vivado install>\bin to it, e.g. C:\AMDDesignTools\2025.1\Vivado\bin" -ForegroundColor Red
    exit 1
}

# Vivado writes logs and a .Xil folder where it runs, so run it in build\fpga.
$fwd = { param($p) $p -replace '\\', '/' }
Push-Location $Out
try {
    & vivado -mode batch -nojournal -log vivado.log -notrace `
        -source (& $fwd (Join-Path $PSScriptRoot 'build.tcl')) -tclargs (& $fwd $hex) $Part (& $fwd $Out)
    if ($LASTEXITCODE -ne 0) { Write-Host "Vivado build failed; see $Out\vivado.log" -ForegroundColor Red; exit 1 }
    $bit = Join-Path $Out 'nexys_top.bit'
    Write-Host "Bitstream: $bit" -ForegroundColor Green

    if ($Program) {
        & vivado -mode batch -nojournal -log program.log -notrace `
            -source (& $fwd (Join-Path $PSScriptRoot 'program.tcl')) -tclargs (& $fwd $bit)
        if ($LASTEXITCODE -ne 0) { Write-Host "Programming failed; see $Out\program.log" -ForegroundColor Red; exit 1 }
    }
}
finally { Pop-Location }
