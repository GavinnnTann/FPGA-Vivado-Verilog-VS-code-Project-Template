## Acoustic Fingerprint Device - Pin Constraints
## Target: CmodA7 rev. B (xc7a35tcpg236-1)
## Subsystems: I2S (INMP441 on Pmod JA), UART TX, Status LED, Buttons

## 12 MHz Clock Signal
set_property -dict { PACKAGE_PIN L17   IOSTANDARD LVCMOS33 } [get_ports { clk }]; #IO_L12P_T1_MRCC_14 Sch=gclk
create_clock -add -name sys_clk_pin -period 83.33 -waveform {0 41.66} [get_ports {clk}];

## Status LED (active-high, accent LED on CMOD A7)
set_property -dict { PACKAGE_PIN A17   IOSTANDARD LVCMOS33 } [get_ports { led }]; #IO_L12N_T1_MRCC_16 Sch=led[1]

## Buttons (active-high, directly on CMOD A7)
set_property -dict { PACKAGE_PIN A18   IOSTANDARD LVCMOS33 PULLDOWN TRUE } [get_ports { btn_start }]; #IO_L19N_T3_VREF_16 Sch=btn[0]
set_property -dict { PACKAGE_PIN B18   IOSTANDARD LVCMOS33 PULLDOWN TRUE } [get_ports { btn_reset }]; #IO_L19P_T3_16 Sch=btn[1]

## I2S Interface — INMP441 on Pmod Header JA (Row 1)
## Wiring: JA[1]=SCK, JA[2]=WS, JA[3]=SD, JA pin 5=GND, JA pin 6=VCC 3.3V
## INMP441 L/R pin tied to GND → left channel active
set_property -dict { PACKAGE_PIN G17   IOSTANDARD LVCMOS33 } [get_ports { i2s_sck }]; #IO_L5N_T0_D07_14 Sch=ja[1]
set_property -dict { PACKAGE_PIN G19   IOSTANDARD LVCMOS33 } [get_ports { i2s_ws  }]; #IO_L4N_T0_D05_14 Sch=ja[2]
set_property -dict { PACKAGE_PIN N18   IOSTANDARD LVCMOS33 } [get_ports { i2s_sd  }]; #IO_L9P_T1_DQS_14 Sch=ja[3]

## UART TX — FPGA → PC via onboard USB-UART (FTDI) bridge
## Note: Port named uart_rxd_out follows FTDI perspective (FPGA transmits, FTDI receives)
set_property -dict { PACKAGE_PIN J18   IOSTANDARD LVCMOS33 } [get_ports { uart_tx }]; #IO_L7N_T1_D10_14 Sch=uart_rxd_out

## Configuration
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
