# TCL script for programming CMOD A7 configuration flash (non-volatile)
# This writes the generated bitstream into external QSPI flash so it survives
# power cycling.

set script_dir [file dirname [file normalize [info script]]]

# Load project configuration
set config_file [file normalize "$script_dir/config.tcl"]
if {![file exists $config_file]} {
    puts "ERROR: Configuration file not found: $config_file"
    puts "Please create config.tcl in the scripts directory"
    exit 1
}
source $config_file

# Set paths based on configuration
if {[file pathtype $BUILD_DIR] eq "absolute"} {
    set project_dir [file normalize $BUILD_DIR]
} else {
    set project_dir [file normalize "$script_dir/../$BUILD_DIR"]
}
set project_name $PROJECT_NAME
set bitstream_file "$project_dir/$project_name.runs/impl_1/$TOP_MODULE.bit"
set cfgmem_file "$project_dir/$project_name.runs/impl_1/$TOP_MODULE.mcs"

# Check if bitstream exists
if {![file exists $bitstream_file]} {
    puts "ERROR: Bitstream file not found: $bitstream_file"
    puts "Please run build.tcl first to generate the bitstream"
    exit 1
}

# Open hardware manager
open_hw_manager
connect_hw_server -allow_non_jtag
open_hw_target

# Select the first connected FPGA device
set device [lindex [get_hw_devices] 0]
if {$device eq ""} {
    puts "ERROR: No hardware devices found"
    close_hw_target
    disconnect_hw_server
    close_hw_manager
    exit 1
}
current_hw_device $device
refresh_hw_device $device

# Resolve a compatible flash part dynamically across Vivado/device variants.
# Prefer single-device SPI definitions known to work on CMOD A7 (Artix-7).
set cfgmem_part ""
set cfgmem_candidates [list \
    "mx25l3273f-spi-x1_x2_x4" \
    "s25fl128sxxxxxx0-spi-x1_x2_x4" \
    "s25fl128sxxxxxx1-spi-x1_x2_x4" \
    "s25fl128l-spi-x1_x2_x4" \
    "mt25ql128-spi-x1_x2_x4" \
    "mx25l3273f*spi*" \
    "s25fl128*spi*" \
    "mt25ql128*spi*" \
]

foreach pattern $cfgmem_candidates {
    set matches [get_cfgmem_parts $pattern]
    if {[llength $matches] > 0} {
        set cfgmem_part [lindex $matches 0]
        break
    }
}

if {$cfgmem_part eq ""} {
    puts "ERROR: Unable to find a supported 128-Mbit SPI cfgmem part in this Vivado install."
    puts "Hint: run 'get_cfgmem_parts *spi*' in Vivado Tcl console to inspect available parts."
    close_hw_target
    disconnect_hw_server
    close_hw_manager
    exit 1
}

puts "Using cfgmem part: $cfgmem_part"

set cfgmem_size_mb 16
if {[string match "*3273f*" $cfgmem_part]} {
    set cfgmem_size_mb 4
}

# Attach configuration memory object to current device.
create_hw_cfgmem -hw_device $device [lindex [get_cfgmem_parts $cfgmem_part] 0]
set cfgmem [get_property PROGRAM.HW_CFGMEM $device]

# Build a flash image from the .bit (CMOD A7 uses 16 MByte SPI configuration flash).
puts "Generating cfgmem image: $cfgmem_file"
write_cfgmem -force \
    -format mcs \
    -size $cfgmem_size_mb \
    -interface SPIx1 \
    -loadbit "up 0x0 $bitstream_file" \
    -file $cfgmem_file

# Program options
set_property PROGRAM.ADDRESS_RANGE {use_file} $cfgmem
set_property PROGRAM.FILES [list $cfgmem_file] $cfgmem
set_property PROGRAM.BPI_RS_PINS {none} $cfgmem
set_property PROGRAM.BLANK_CHECK 0 $cfgmem
set_property PROGRAM.ERASE 1 $cfgmem
set_property PROGRAM.CFG_PROGRAM 1 $cfgmem
set_property PROGRAM.VERIFY 1 $cfgmem

startgroup
# Ensure device is prepared for indirect flash programming.
if {![string equal [get_property PROGRAM.HW_CFGMEM_TYPE $device] \
                   [get_property MEM_TYPE [get_property CFGMEM_PART $cfgmem]]]} {
    create_hw_bitstream -hw_device $device [get_property PROGRAM.HW_CFGMEM_BITFILE $device]
    program_hw_devices $device
}

puts "Flashing cfgmem with bitstream: $bitstream_file"
program_hw_cfgmem -hw_cfgmem $cfgmem
endgroup

refresh_hw_device $device
puts "Flash programming completed successfully!"
puts "Power-cycle or reset the board; it should now boot from QSPI flash."

close_hw_target
disconnect_hw_server
close_hw_manager
