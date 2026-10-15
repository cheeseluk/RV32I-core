## Pins for nexys_top on the Nexys A7 (100T and 50T; the Nexys 4 DDR is the same).
## From Digilent's Nexys-A7-100T-Master.xdc, keeping only the pins used.

## 100 MHz clock. The MMCM in nexys_top derives the core clock from it, and
## Vivado works out that clock's constraint from this one.
set_property -dict { PACKAGE_PIN E3  IOSTANDARD LVCMOS33 } [get_ports CLK100MHZ]
create_clock -name sys_clk -period 10.00 [get_ports CLK100MHZ]

## CPU_RESET button (red, active low)
set_property -dict { PACKAGE_PIN C12 IOSTANDARD LVCMOS33 } [get_ports CPU_RESETN]

## Switches (SW8 and SW9 are in a 1.8 V bank)
set_property -dict { PACKAGE_PIN J15 IOSTANDARD LVCMOS33 } [get_ports {SW[0]}]
set_property -dict { PACKAGE_PIN L16 IOSTANDARD LVCMOS33 } [get_ports {SW[1]}]
set_property -dict { PACKAGE_PIN M13 IOSTANDARD LVCMOS33 } [get_ports {SW[2]}]
set_property -dict { PACKAGE_PIN R15 IOSTANDARD LVCMOS33 } [get_ports {SW[3]}]
set_property -dict { PACKAGE_PIN R17 IOSTANDARD LVCMOS33 } [get_ports {SW[4]}]
set_property -dict { PACKAGE_PIN T18 IOSTANDARD LVCMOS33 } [get_ports {SW[5]}]
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports {SW[6]}]
set_property -dict { PACKAGE_PIN R13 IOSTANDARD LVCMOS33 } [get_ports {SW[7]}]
set_property -dict { PACKAGE_PIN T8  IOSTANDARD LVCMOS18 } [get_ports {SW[8]}]
set_property -dict { PACKAGE_PIN U8  IOSTANDARD LVCMOS18 } [get_ports {SW[9]}]
set_property -dict { PACKAGE_PIN R16 IOSTANDARD LVCMOS33 } [get_ports {SW[10]}]
set_property -dict { PACKAGE_PIN T13 IOSTANDARD LVCMOS33 } [get_ports {SW[11]}]
set_property -dict { PACKAGE_PIN H6  IOSTANDARD LVCMOS33 } [get_ports {SW[12]}]
set_property -dict { PACKAGE_PIN U12 IOSTANDARD LVCMOS33 } [get_ports {SW[13]}]
set_property -dict { PACKAGE_PIN U11 IOSTANDARD LVCMOS33 } [get_ports {SW[14]}]
set_property -dict { PACKAGE_PIN V10 IOSTANDARD LVCMOS33 } [get_ports {SW[15]}]

## LEDs
set_property -dict { PACKAGE_PIN H17 IOSTANDARD LVCMOS33 } [get_ports {LED[0]}]
set_property -dict { PACKAGE_PIN K15 IOSTANDARD LVCMOS33 } [get_ports {LED[1]}]
set_property -dict { PACKAGE_PIN J13 IOSTANDARD LVCMOS33 } [get_ports {LED[2]}]
set_property -dict { PACKAGE_PIN N14 IOSTANDARD LVCMOS33 } [get_ports {LED[3]}]
set_property -dict { PACKAGE_PIN R18 IOSTANDARD LVCMOS33 } [get_ports {LED[4]}]
set_property -dict { PACKAGE_PIN V17 IOSTANDARD LVCMOS33 } [get_ports {LED[5]}]
set_property -dict { PACKAGE_PIN U17 IOSTANDARD LVCMOS33 } [get_ports {LED[6]}]
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports {LED[7]}]
set_property -dict { PACKAGE_PIN V16 IOSTANDARD LVCMOS33 } [get_ports {LED[8]}]
set_property -dict { PACKAGE_PIN T15 IOSTANDARD LVCMOS33 } [get_ports {LED[9]}]
set_property -dict { PACKAGE_PIN U14 IOSTANDARD LVCMOS33 } [get_ports {LED[10]}]
set_property -dict { PACKAGE_PIN T16 IOSTANDARD LVCMOS33 } [get_ports {LED[11]}]
set_property -dict { PACKAGE_PIN V15 IOSTANDARD LVCMOS33 } [get_ports {LED[12]}]
set_property -dict { PACKAGE_PIN V14 IOSTANDARD LVCMOS33 } [get_ports {LED[13]}]
set_property -dict { PACKAGE_PIN V12 IOSTANDARD LVCMOS33 } [get_ports {LED[14]}]
set_property -dict { PACKAGE_PIN V11 IOSTANDARD LVCMOS33 } [get_ports {LED[15]}]

## RGB LEDs
set_property -dict { PACKAGE_PIN R12 IOSTANDARD LVCMOS33 } [get_ports LED16_B]
set_property -dict { PACKAGE_PIN M16 IOSTANDARD LVCMOS33 } [get_ports LED16_G]
set_property -dict { PACKAGE_PIN N15 IOSTANDARD LVCMOS33 } [get_ports LED16_R]
set_property -dict { PACKAGE_PIN G14 IOSTANDARD LVCMOS33 } [get_ports LED17_B]
set_property -dict { PACKAGE_PIN R11 IOSTANDARD LVCMOS33 } [get_ports LED17_G]
set_property -dict { PACKAGE_PIN N16 IOSTANDARD LVCMOS33 } [get_ports LED17_R]

## 7-segment display: segments (shared by all digits) and digit anodes, active low
set_property -dict { PACKAGE_PIN T10 IOSTANDARD LVCMOS33 } [get_ports CA]
set_property -dict { PACKAGE_PIN R10 IOSTANDARD LVCMOS33 } [get_ports CB]
set_property -dict { PACKAGE_PIN K16 IOSTANDARD LVCMOS33 } [get_ports CC]
set_property -dict { PACKAGE_PIN K13 IOSTANDARD LVCMOS33 } [get_ports CD]
set_property -dict { PACKAGE_PIN P15 IOSTANDARD LVCMOS33 } [get_ports CE]
set_property -dict { PACKAGE_PIN T11 IOSTANDARD LVCMOS33 } [get_ports CF]
set_property -dict { PACKAGE_PIN L18 IOSTANDARD LVCMOS33 } [get_ports CG]
set_property -dict { PACKAGE_PIN H15 IOSTANDARD LVCMOS33 } [get_ports DP]
set_property -dict { PACKAGE_PIN J17 IOSTANDARD LVCMOS33 } [get_ports {AN[0]}]
set_property -dict { PACKAGE_PIN J18 IOSTANDARD LVCMOS33 } [get_ports {AN[1]}]
set_property -dict { PACKAGE_PIN T9  IOSTANDARD LVCMOS33 } [get_ports {AN[2]}]
set_property -dict { PACKAGE_PIN J14 IOSTANDARD LVCMOS33 } [get_ports {AN[3]}]
set_property -dict { PACKAGE_PIN P14 IOSTANDARD LVCMOS33 } [get_ports {AN[4]}]
set_property -dict { PACKAGE_PIN T14 IOSTANDARD LVCMOS33 } [get_ports {AN[5]}]
set_property -dict { PACKAGE_PIN K2  IOSTANDARD LVCMOS33 } [get_ports {AN[6]}]
set_property -dict { PACKAGE_PIN U13 IOSTANDARD LVCMOS33 } [get_ports {AN[7]}]

## Buttons and switches are synchronized in nexys_top, and the LEDs and display
## are only seen by people, so no timing on any of these pins.
set_false_path -from [get_ports {CPU_RESETN SW[*]}]
set_false_path -to   [get_ports {LED[*] LED16_* LED17_* AN[*] CA CB CC CD CE CF CG DP}]

## Configuration bank voltage, so the bitstream DRC doesn't warn
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
