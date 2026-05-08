# Board configuration: Digilent Nexys A7-100T
# Sourced automatically by build.tcl and flash.tcl via the BOARD variable in config.tcl

set BOARD_DISPLAY_NAME "Digilent Nexys A7-100T"
set PART_NAME          "xc7a100tcsg324-1"
set CLOCK_MHZ          100
set CLOCK_PERIOD_NS    10.00
set CLOCK_HALF_NS      5.00
set CLOCK_PIN          "E3"

# Configuration flash parameters (SPI, 128 Mbit / 16 MB)
set CFGMEM_CANDIDATES [list \
    "s25fl128sxxxxxx0-spi-x1_x2_x4" \
    "s25fl128sxxxxxx1-spi-x1_x2_x4" \
    "mt25ql128-spi-x1_x2_x4"        \
    "s25fl128*spi*"                  \
]
set CFGMEM_SIZE_MB  16
set CFGMEM_INTERFACE "SPIx4"
