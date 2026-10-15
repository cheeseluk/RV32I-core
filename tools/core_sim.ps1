# Helpers shared by run_prog.ps1 and run_tests.ps1. Dot-source this file.

$Root  = Split-Path $PSScriptRoot -Parent
$Build = Join-Path $Root 'build'
$Gcc   = 'riscv64-unknown-elf-gcc'
$GccFlags = @('-march=rv32i', '-mabi=ilp32', '-mno-relax', '-Wl,--no-warn-rwx-segments', '-nostdlib', '-nostartfiles',
              '-T', (Join-Path $Root 'sw\link.ld'))

# Compile core_tb and every design file into build\core_tb.vvp (same file list as sim.ps1).
function Build-CoreTb {
    New-Item -ItemType Directory -Force $Build | Out-Null
    $sources = @(Get-ChildItem (Join-Path $Root 'rtl') -Filter *.sv |
        Sort-Object { $_.BaseName -notlike '*_pkg' }, Name |
        ForEach-Object { $_.FullName })
    # -g2012: SystemVerilog. iverilog's "sorry: constant selects" notes are harmless.
    $out = & iverilog -g2012 -s core_tb -o "$Build\core_tb.vvp" $sources (Join-Path $Root 'tb\core_tb.sv') 2>&1
    $out | Where-Object { "$_" -notmatch 'sorry: constant selects' } | ForEach-Object { Write-Host $_ }
    return ($LASTEXITCODE -eq 0)
}

# Build one .S or .c file and write <OutDir>\<name>.hex. Returns the hex path, or $null.
# A .c file is linked with sw\c\crt0.S (stack, .bss, result) and libgcc (mul/div).
function Build-Hex([string]$Source, [string]$OutDir, [string[]]$ExtraFlags = @()) {
    New-Item -ItemType Directory -Force $OutDir | Out-Null
    $name = [IO.Path]::GetFileNameWithoutExtension($Source)
    $elf  = Join-Path $OutDir "$name.elf"
    $bin  = Join-Path $OutDir "$name.bin"
    $hex  = Join-Path $OutDir "$name.hex"
    if ([IO.Path]::GetExtension($Source) -eq '.c') {
        & $Gcc @GccFlags '-O2' '-ffreestanding' @ExtraFlags (Join-Path $Root 'sw\c\crt0.S') $Source '-lgcc' -o $elf
    } else {
        & $Gcc @GccFlags @ExtraFlags $Source -o $elf
    }
    if ($LASTEXITCODE -ne 0) { return $null }
    & riscv64-unknown-elf-objcopy -O binary $elf $bin
    & riscv64-unknown-elf-objdump -d -M no-aliases $elf > (Join-Path $OutDir "$name.dump")
    & python (Join-Path $Root 'tools\bin2hex.py') $bin $hex
    return $hex
}

# Run the hex on the core and on the reference model, then diff the traces.
# Returns an object with the core's verdict, the model's verdict, and the diff result.
function Invoke-Program([string]$Hex, [switch]$ShowTrace, [int]$MaxCycles = 100000) {
    $coreTrace = [IO.Path]::ChangeExtension($Hex, 'core.trace')
    $refTrace  = [IO.Path]::ChangeExtension($Hex, 'ref.trace')

    $simArgs = @("+hex=$Hex", "+trace=$coreTrace", "+max_cycles=$MaxCycles")
    if ($ShowTrace) { $simArgs += '+verbose' }
    Push-Location $Build
    try     { $simOut = @(& vvp -n core_tb.vvp @simArgs) }
    finally { Pop-Location }
    if ($ShowTrace) {
        $simOut | Where-Object { $_ -notmatch '^(PASS|FAIL)|\$finish called' } | ForEach-Object { Write-Host "  $_" }
    }

    $refOut  = @(& python (Join-Path $Root 'tools\iss.py') $Hex --trace $refTrace --max-steps $MaxCycles)
    $diffOut = @(& python (Join-Path $Root 'tools\trace_diff.py') $coreTrace $refTrace)
    $match   = ($LASTEXITCODE -eq 0)

    [pscustomobject]@{
        Core  = ($simOut | Where-Object { $_ -match '^(PASS|FAIL)' } | Select-Object -First 1)
        Ref   = ($refOut | Select-Object -Last 1)
        Match = $match
        Diff  = $diffOut
    }
}

# One summary line per program. Returns $true when the core passed AND matched the model.
function Write-Result([string]$Name, $r) {
    if (-not $r.Core) { $r.Core = 'FAIL (no verdict from simulation)' }
    $ok = ($r.Core -eq 'PASS') -and $r.Match
    $color = if ($ok) { 'Green' } else { 'Red' }
    $trace = if ($r.Match) { 'trace matches model' } else { 'TRACE MISMATCH' }
    Write-Host ("{0,-6} {1,-10} {2}  [{3}]" -f ($(if ($ok) { 'PASS' } else { 'FAIL' })), $Name, $r.Core, $trace) -ForegroundColor $color
    if (-not $r.Match) { $r.Diff | ForEach-Object { Write-Host "         $_" } }
    if ($r.Ref -ne $r.Core) { Write-Host "         reference model says: $($r.Ref)" }
    return $ok
}
