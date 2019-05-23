# leds
set_property PACKAGE_PIN M14 [get_ports {led_n[3]}]
set_property PACKAGE_PIN M15 [get_ports {led_n[2]}]
set_property PACKAGE_PIN G14 [get_ports {led_n[1]}]
set_property PACKAGE_PIN D18 [get_ports {led_n[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports led_n]

# external reset
set_property PACKAGE_PIN R18  [get_ports ext_rst]
set_property IOSTANDARD LVCMOS33 [get_ports ext_rst]

# hdmi input
set_property PACKAGE_PIN H16 [get_ports tmds_in_clk_p]
set_property PACKAGE_PIN H17 [get_ports tmds_in_clk_n]

set_property PACKAGE_PIN D19 [get_ports tmds_in_d0_p]
set_property PACKAGE_PIN D20 [get_ports tmds_in_d0_n]

set_property PACKAGE_PIN C20 [get_ports tmds_in_d1_p]
set_property PACKAGE_PIN B20 [get_ports tmds_in_d1_n]

set_property PACKAGE_PIN B19 [get_ports tmds_in_d2_p]
set_property PACKAGE_PIN A20 [get_ports tmds_in_d2_n]

set_property PACKAGE_PIN E18 [get_ports tmds_in_hpd]

set_property PACKAGE_PIN G18 [get_ports tmds_in_sda]
set_property PACKAGE_PIN G17 [get_ports tmds_in_scl]

# hdmi io standard
set_property IOSTANDARD TMDS_33 [get_ports tmds_in_clk_*]
set_property IOSTANDARD TMDS_33 [get_ports tmds_in_d*]

set_property IOSTANDARD LVCMOS33 [get_ports tmds_in_hpd]

set_property IOSTANDARD LVCMOS33 [get_ports tmds_in_sda]
set_property IOSTANDARD LVCMOS33 [get_ports tmds_in_scl]

# i2c pullups
set_property PULLUP true [get_ports tmds_in_sda]
set_property PULLUP true [get_ports tmds_in_scl]
