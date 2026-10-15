# Loads a bitstream onto the board over the USB (JTAG) cable.
# build.ps1 -Program runs it:  vivado -mode batch -source fpga/program.tcl -tclargs <bitfile>
# The FPGA forgets it at power-off; the board then loads whatever is in its flash.

set bit [lindex $argv 0]

open_hw_manager
connect_hw_server
open_hw_target
set dev [lindex [get_hw_devices xc7a*] 0]
current_hw_device $dev
set_property PROGRAM.FILE $bit $dev
program_hw_devices $dev
close_hw_manager
