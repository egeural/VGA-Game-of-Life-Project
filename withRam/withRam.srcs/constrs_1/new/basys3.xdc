## Clock (100MHz)
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name sys_clk -waveform {0.000 5.000} [get_ports clk]

## Reset (Center button - active high)
set_property PACKAGE_PIN T3 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

## Directional Buttons (with explicit constraints)
set_property PACKAGE_PIN T18 [get_ports btn_up]    
set_property IOSTANDARD LVCMOS33 [get_ports btn_up]

set_property PACKAGE_PIN U17 [get_ports btn_down]  
set_property IOSTANDARD LVCMOS33 [get_ports btn_down]

set_property PACKAGE_PIN T17 [get_ports btn_right] 
set_property IOSTANDARD LVCMOS33 [get_ports btn_right]

set_property PACKAGE_PIN W19 [get_ports btn_left]  
set_property IOSTANDARD LVCMOS33 [get_ports btn_left]

## VGA Red (4-bit)
set_property PACKAGE_PIN G19 [get_ports {red[0]}]
set_property PACKAGE_PIN H19 [get_ports {red[1]}]
set_property PACKAGE_PIN J19 [get_ports {red[2]}]
set_property PACKAGE_PIN N19 [get_ports {red[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {red[*]}]

## VGA Green
set_property PACKAGE_PIN J17 [get_ports {green[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {green[0]}]
set_property PACKAGE_PIN H17 [get_ports {green[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {green[1]}]
set_property PACKAGE_PIN G17 [get_ports {green[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {green[2]}]
set_property PACKAGE_PIN D17 [get_ports {green[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {green[3]}]

## VGA Blue
set_property PACKAGE_PIN N18 [get_ports {blue[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {blue[0]}]
set_property PACKAGE_PIN L18 [get_ports {blue[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {blue[1]}]
set_property PACKAGE_PIN K18 [get_ports {blue[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {blue[2]}]
set_property PACKAGE_PIN J18 [get_ports {blue[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {blue[3]}]

## Center Button (BTNC - Drawing)
set_property PACKAGE_PIN U18 [get_ports btn_center]
set_property IOSTANDARD LVCMOS33 [get_ports btn_center]

## Clear Canvas Switch (Rightmost switch)
set_property PACKAGE_PIN V17 [get_ports clear_switch]
set_property IOSTANDARD LVCMOS33 [get_ports clear_switch]

## Start/Stop Simulation Switch
set_property PACKAGE_PIN V16 [get_ports start_switch]
set_property IOSTANDARD LVCMOS33 [get_ports start_switch]

## Sync
set_property PACKAGE_PIN P19 [get_ports hsync]
set_property IOSTANDARD LVCMOS33 [get_ports hsync]
set_property PACKAGE_PIN R19 [get_ports vsync]
set_property IOSTANDARD LVCMOS33 [get_ports vsync]