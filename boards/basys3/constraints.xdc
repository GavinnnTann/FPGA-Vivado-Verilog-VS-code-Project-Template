## Reference constraint file for Digilent Basys3
## Clock: W5, 100 MHz
## To use: uncomment and rename ports to match your top-level signals

## Clock
set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5.00} [get_ports {clk}];

## LEDs (active-high)
#set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports { led[0]  }];
#set_property -dict { PACKAGE_PIN E19 IOSTANDARD LVCMOS33 } [get_ports { led[1]  }];
#set_property -dict { PACKAGE_PIN U19 IOSTANDARD LVCMOS33 } [get_ports { led[2]  }];
#set_property -dict { PACKAGE_PIN V19 IOSTANDARD LVCMOS33 } [get_ports { led[3]  }];
#set_property -dict { PACKAGE_PIN W18 IOSTANDARD LVCMOS33 } [get_ports { led[4]  }];
#set_property -dict { PACKAGE_PIN U15 IOSTANDARD LVCMOS33 } [get_ports { led[5]  }];
#set_property -dict { PACKAGE_PIN U14 IOSTANDARD LVCMOS33 } [get_ports { led[6]  }];
#set_property -dict { PACKAGE_PIN V14 IOSTANDARD LVCMOS33 } [get_ports { led[7]  }];
#set_property -dict { PACKAGE_PIN V13 IOSTANDARD LVCMOS33 } [get_ports { led[8]  }];
#set_property -dict { PACKAGE_PIN V3  IOSTANDARD LVCMOS33 } [get_ports { led[9]  }];
#set_property -dict { PACKAGE_PIN W3  IOSTANDARD LVCMOS33 } [get_ports { led[10] }];
#set_property -dict { PACKAGE_PIN U3  IOSTANDARD LVCMOS33 } [get_ports { led[11] }];
#set_property -dict { PACKAGE_PIN P3  IOSTANDARD LVCMOS33 } [get_ports { led[12] }];
#set_property -dict { PACKAGE_PIN N3  IOSTANDARD LVCMOS33 } [get_ports { led[13] }];
#set_property -dict { PACKAGE_PIN P1  IOSTANDARD LVCMOS33 } [get_ports { led[14] }];
#set_property -dict { PACKAGE_PIN L1  IOSTANDARD LVCMOS33 } [get_ports { led[15] }];

## Switches (active-high)
#set_property -dict { PACKAGE_PIN V17 IOSTANDARD LVCMOS33 } [get_ports { sw[0]  }];
#set_property -dict { PACKAGE_PIN V16 IOSTANDARD LVCMOS33 } [get_ports { sw[1]  }];
#set_property -dict { PACKAGE_PIN W16 IOSTANDARD LVCMOS33 } [get_ports { sw[2]  }];
#set_property -dict { PACKAGE_PIN W17 IOSTANDARD LVCMOS33 } [get_ports { sw[3]  }];
#set_property -dict { PACKAGE_PIN W15 IOSTANDARD LVCMOS33 } [get_ports { sw[4]  }];
#set_property -dict { PACKAGE_PIN V15 IOSTANDARD LVCMOS33 } [get_ports { sw[5]  }];
#set_property -dict { PACKAGE_PIN W14 IOSTANDARD LVCMOS33 } [get_ports { sw[6]  }];
#set_property -dict { PACKAGE_PIN W13 IOSTANDARD LVCMOS33 } [get_ports { sw[7]  }];
#set_property -dict { PACKAGE_PIN V2  IOSTANDARD LVCMOS33 } [get_ports { sw[8]  }];
#set_property -dict { PACKAGE_PIN T3  IOSTANDARD LVCMOS33 } [get_ports { sw[9]  }];
#set_property -dict { PACKAGE_PIN T2  IOSTANDARD LVCMOS33 } [get_ports { sw[10] }];
#set_property -dict { PACKAGE_PIN R3  IOSTANDARD LVCMOS33 } [get_ports { sw[11] }];
#set_property -dict { PACKAGE_PIN W2  IOSTANDARD LVCMOS33 } [get_ports { sw[12] }];
#set_property -dict { PACKAGE_PIN U1  IOSTANDARD LVCMOS33 } [get_ports { sw[13] }];
#set_property -dict { PACKAGE_PIN T1  IOSTANDARD LVCMOS33 } [get_ports { sw[14] }];
#set_property -dict { PACKAGE_PIN R2  IOSTANDARD LVCMOS33 } [get_ports { sw[15] }];

## Buttons (active-high)
#set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports { btnc }];
#set_property -dict { PACKAGE_PIN T18 IOSTANDARD LVCMOS33 } [get_ports { btnu }];
#set_property -dict { PACKAGE_PIN W19 IOSTANDARD LVCMOS33 } [get_ports { btnl }];
#set_property -dict { PACKAGE_PIN T17 IOSTANDARD LVCMOS33 } [get_ports { btnr }];
#set_property -dict { PACKAGE_PIN U17 IOSTANDARD LVCMOS33 } [get_ports { btnd }];

## 7-Segment cathodes (active-low segments)
#set_property -dict { PACKAGE_PIN W7 IOSTANDARD LVCMOS33 } [get_ports { seg[0] }]; ## CA
#set_property -dict { PACKAGE_PIN W6 IOSTANDARD LVCMOS33 } [get_ports { seg[1] }]; ## CB
#set_property -dict { PACKAGE_PIN U8 IOSTANDARD LVCMOS33 } [get_ports { seg[2] }]; ## CC
#set_property -dict { PACKAGE_PIN V8 IOSTANDARD LVCMOS33 } [get_ports { seg[3] }]; ## CD
#set_property -dict { PACKAGE_PIN U5 IOSTANDARD LVCMOS33 } [get_ports { seg[4] }]; ## CE
#set_property -dict { PACKAGE_PIN V5 IOSTANDARD LVCMOS33 } [get_ports { seg[5] }]; ## CF
#set_property -dict { PACKAGE_PIN U7 IOSTANDARD LVCMOS33 } [get_ports { seg[6] }]; ## CG
#set_property -dict { PACKAGE_PIN V7 IOSTANDARD LVCMOS33 } [get_ports { dp }];     ## DP

## 7-Segment anodes (active-low digit select)
#set_property -dict { PACKAGE_PIN U2 IOSTANDARD LVCMOS33 } [get_ports { an[0] }];
#set_property -dict { PACKAGE_PIN U4 IOSTANDARD LVCMOS33 } [get_ports { an[1] }];
#set_property -dict { PACKAGE_PIN V4 IOSTANDARD LVCMOS33 } [get_ports { an[2] }];
#set_property -dict { PACKAGE_PIN W4 IOSTANDARD LVCMOS33 } [get_ports { an[3] }];

## Pmod JA
#set_property -dict { PACKAGE_PIN J1 IOSTANDARD LVCMOS33 } [get_ports { ja[0] }];
#set_property -dict { PACKAGE_PIN L2 IOSTANDARD LVCMOS33 } [get_ports { ja[1] }];
#set_property -dict { PACKAGE_PIN J2 IOSTANDARD LVCMOS33 } [get_ports { ja[2] }];
#set_property -dict { PACKAGE_PIN G2 IOSTANDARD LVCMOS33 } [get_ports { ja[3] }];
#set_property -dict { PACKAGE_PIN H1 IOSTANDARD LVCMOS33 } [get_ports { ja[4] }];
#set_property -dict { PACKAGE_PIN K2 IOSTANDARD LVCMOS33 } [get_ports { ja[5] }];
#set_property -dict { PACKAGE_PIN H2 IOSTANDARD LVCMOS33 } [get_ports { ja[6] }];
#set_property -dict { PACKAGE_PIN G3 IOSTANDARD LVCMOS33 } [get_ports { ja[7] }];

## UART
#set_property -dict { PACKAGE_PIN B18 IOSTANDARD LVCMOS33 } [get_ports { uart_txd_in  }];
#set_property -dict { PACKAGE_PIN A18 IOSTANDARD LVCMOS33 } [get_ports { uart_rxd_out }];
