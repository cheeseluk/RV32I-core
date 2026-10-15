# Builds the bitstream for nexys_top with Vivado in non-project mode.
# build.ps1 runs it:  vivado -mode batch -source fpga/build.tcl -tclargs <hex> <part> <outdir>
# Paths use forward slashes.

lassign $argv hex part out
set root [file normalize [file join [file dirname [info script]] ..]]
file mkdir $out

# riscv_pkg first: the other files import it.
read_verilog -sv [file join $root rtl riscv_pkg.sv]
foreach f [lsort [glob [file join $root rtl *.sv]]] {
    if {[file tail $f] ne "riscv_pkg.sv"} { read_verilog -sv $f }
}
read_verilog -sv [list [file join $root fpga sevenseg.sv] [file join $root fpga nexys_top.sv]]
read_xdc [file join $root fpga nexys_a7.xdc]

# HEX is a string parameter, so its value keeps its quotes: HEX="C:/.../prog.hex".
# $readmemh loads it into imem and dmem at synthesis time.
synth_design -top nexys_top -part $part -generic HEX="$hex"
opt_design
place_design
route_design

report_utilization    -file [file join $out utilization.rpt]
report_utilization    -file [file join $out utilization_hier.rpt] -hierarchical
report_timing_summary -file [file join $out timing.rpt]
report_power          -file [file join $out power.rpt]

set wns [get_property SLACK [get_timing_paths -delay_type max]]
puts "Worst setup slack: $wns ns (timing report: [file join $out timing.rpt])"
if {$wns < 0} {
    puts "WARNING: timing is not met, so the core may misbehave on the board."
    puts "         Lower the core clock: raise CLK_DIV in fpga/nexys_top.sv."
}

write_bitstream -force [file join $out nexys_top.bit]
