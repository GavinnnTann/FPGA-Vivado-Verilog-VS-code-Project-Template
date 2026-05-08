# Board configuration: Digilent CMOD A7-35T
# Sourced automatically by build.tcl and flash.tcl via the BOARD variable in config.tcl

set BOARD_DISPLAY_NAME "Digilent CMOD A7-35T"
set PART_NAME          "xc7a35tcpg236-1"
set CLOCK_MHZ          12
set CLOCK_PERIOD_NS    83.33
set CLOCK_HALF_NS      41.66
set CLOCK_PIN          "L17"

# Configuration flash parameters (QSPI, 32 Mbit / 4 MB)
set CFGMEM_CANDIDATES [list \
    "mx25l3273f-spi-x1_x2_x4" \
    "s25fl032p-spi-x1_x2_x4"  \
    "mx25l3273f*spi*"          \
]
set CFGMEM_SIZE_MB  4
set CFGMEM_INTERFACE "SPIx1"
