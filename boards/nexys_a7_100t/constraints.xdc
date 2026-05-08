## Reference constraint file for Digilent Nexys A7-100T
## Clock: E3, 100 MHz
## To use: uncomment and rename ports to match your top-level signals

## Clock
set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5.00} [get_ports {clk}];

## LEDs (active-high)
#set_property -dict { PACKAGE_PIN H17 IOSTANDARD LVCMOS33 } [get_ports { led[0]  }];
#set_property -dict { PACKAGE_PIN K15 IOSTANDARD LVCMOS33 } [get_ports { led[1]  }];
#set_property -dict { PACKAGE_PIN J13 IOSTANDARD LVCMOS33 } [get_ports { led[2]  }];
#set_property -dict { PACKAGE_PIN N14 IOSTANDARD LVCMOS33 } [get_ports { led[3]  }];
#set_property -dict { PACKAGE_PIN R18 IOSTANDARD LVCMOS33 } [get_ports { led[4]  }];
#set_property -dict { PACKAGE_PIN V17 IOSTANDARD LVCMOS33 } [get_ports { led[5]  }];
#set_property -dict { PACKAGE_PIN U17 IOSTANDARD LVCMOS33 } [get_ports { led[6]  }];
#set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports { led[7]  }];
#set_property -dict { PACKAGE_PIN V16 IOSTANDARD LVCMOS33 } [get_ports { led[8]  }];
#set_property -dict { PACKAGE_PIN T15 IOSTANDARD LVCMOS33 } [get_ports { led[9]  }];
#set_property -dict { PACKAGE_PIN U14 IOSTANDARD LVCMOS33 } [get_ports { led[10] }];
#set_property -dict { PACKAGE_PIN T16 IOSTANDARD LVCMOS33 } [get_ports { led[11] }];
#set_property -dict { PACKAGE_PIN V15 IOSTANDARD LVCMOS33 } [get_ports { led[12] }];
#set_property -dict { PACKAGE_PIN V14 IOSTANDARD LVCMOS33 } [get_ports { led[13] }];
#set_property -dict { PACKAGE_PIN V12 IOSTANDARD LVCMOS33 } [get_ports { led[14] }];
#set_property -dict { PACKAGE_PIN V11 IOSTANDARD LVCMOS33 } [get_ports { led[15] }];

## Switches (active-high)
#set_property -dict { PACKAGE_PIN J15 IOSTANDARD LVCMOS12 } [get_ports { sw[0]  }];
#set_property -dict { PACKAGE_PIN L16 IOSTANDARD LVCMOS12 } [get_ports { sw[1]  }];
#set_property -dict { PACKAGE_PIN M13 IOSTANDARD LVCMOS12 } [get_ports { sw[2]  }];
#set_property -dict { PACKAGE_PIN R15 IOSTANDARD LVCMOS12 } [get_ports { sw[3]  }];
#set_property -dict { PACKAGE_PIN R17 IOSTANDARD LVCMOS12 } [get_ports { sw[4]  }];
#set_property -dict { PACKAGE_PIN T18 IOSTANDARD LVCMOS12 } [get_ports { sw[5]  }];
#set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS12 } [get_ports { sw[6]  }];
#set_property -dict { PACKAGE_PIN R13 IOSTANDARD LVCMOS12 } [get_ports { sw[7]  }];
#set_property -dict { PACKAGE_PIN T8  IOSTANDARD LVCMOS18 } [get_ports { sw[8]  }];
#set_property -dict { PACKAGE_PIN U8  IOSTANDARD LVCMOS18 } [get_ports { sw[9]  }];
#set_property -dict { PACKAGE_PIN R16 IOSTANDARD LVCMOS12 } [get_ports { sw[10] }];
#set_property -dict { PACKAGE_PIN T13 IOSTANDARD LVCMOS12 } [get_ports { sw[11] }];
#set_property -dict { PACKAGE_PIN H6  IOSTANDARD LVCMOS12 } [get_ports { sw[12] }];
#set_property -dict { PACKAGE_PIN U12 IOSTANDARD LVCMOS18 } [get_ports { sw[13] }];
#set_property -dict { PACKAGE_PIN U11 IOSTANDARD LVCMOS18 } [get_ports { sw[14] }];
#set_property -dict { PACKAGE_PIN V10 IOSTANDARD LVCMOS18 } [get_ports { sw[15] }];

## Buttons (active-high)
#set_property -dict { PACKAGE_PIN N17 IOSTANDARD LVCMOS33 } [get_ports { btnc }];
#set_property -dict { PACKAGE_PIN M18 IOSTANDARD LVCMOS33 } [get_ports { btnu }];
#set_property -dict { PACKAGE_PIN P17 IOSTANDARD LVCMOS33 } [get_ports { btnl }];
#set_property -dict { PACKAGE_PIN M17 IOSTANDARD LVCMOS33 } [get_ports { btnr }];
#set_property -dict { PACKAGE_PIN P18 IOSTANDARD LVCMOS33 } [get_ports { btnd }];

## 7-Segment cathodes (active-low segments)
#set_property -dict { PACKAGE_PIN T10 IOSTANDARD LVCMOS33 } [get_ports { seg[0] }]; ## CA
#set_property -dict { PACKAGE_PIN R10 IOSTANDARD LVCMOS33 } [get_ports { seg[1] }]; ## CB
#set_property -dict { PACKAGE_PIN K16 IOSTANDARD LVCMOS33 } [get_ports { seg[2] }]; ## CC
#set_property -dict { PACKAGE_PIN K13 IOSTANDARD LVCMOS33 } [get_ports { seg[3] }]; ## CD
#set_property -dict { PACKAGE_PIN P15 IOSTANDARD LVCMOS33 } [get_ports { seg[4] }]; ## CE
#set_property -dict { PACKAGE_PIN T11 IOSTANDARD LVCMOS33 } [get_ports { seg[5] }]; ## CF
#set_property -dict { PACKAGE_PIN L18 IOSTANDARD LVCMOS33 } [get_ports { seg[6] }]; ## CG
#set_property -dict { PACKAGE_PIN H15 IOSTANDARD LVCMOS33 } [get_ports { dp }];     ## DP

## 7-Segment anodes (active-low digit select, 8 digits)
#set_property -dict { PACKAGE_PIN J17 IOSTANDARD LVCMOS33 } [get_ports { an[0] }];
#set_property -dict { PACKAGE_PIN J18 IOSTANDARD LVCMOS33 } [get_ports { an[1] }];
#set_property -dict { PACKAGE_PIN T9  IOSTANDARD LVCMOS33 } [get_ports { an[2] }];
#set_property -dict { PACKAGE_PIN J14 IOSTANDARD LVCMOS33 } [get_ports { an[3] }];
#set_property -dict { PACKAGE_PIN P14 IOSTANDARD LVCMOS33 } [get_ports { an[4] }];
#set_property -dict { PACKAGE_PIN T14 IOSTANDARD LVCMOS33 } [get_ports { an[5] }];
#set_property -dict { PACKAGE_PIN K2  IOSTANDARD LVCMOS33 } [get_ports { an[6] }];
#set_property -dict { PACKAGE_PIN U13 IOSTANDARD LVCMOS33 } [get_ports { an[7] }];

## UART (USB-UART bridge)
#set_property -dict { PACKAGE_PIN C4 IOSTANDARD LVCMOS33 } [get_ports { uart_txd_in  }];
#set_property -dict { PACKAGE_PIN D4 IOSTANDARD LVCMOS33 } [get_ports { uart_rxd_out }];
