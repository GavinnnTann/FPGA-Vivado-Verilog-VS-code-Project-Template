# TCL script for programming CMOD A7 via JTAG
# This script programs the FPGA with the generated bitstream

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
set project_dir [file normalize "$script_dir/../$BUILD_DIR"]
set project_name $PROJECT_NAME
set bitstream_file "$project_dir/$project_name.runs/impl_1/$TOP_MODULE.bit"

# Check if bitstream exists
if {![file exists $bitstream_file]} {
    puts "ERROR: Bitstream file not found: $bitstream_file"
    puts "Please run build.tcl first to generate the bitstream"
    exit 1
}

# Open hardware manager
open_hw_manager

# Connect to hardware server
connect_hw_server -allow_non_jtag

# Open target board
open_hw_target

# Set the current hardware device
set device [lindex [get_hw_devices] 0]
current_hw_device $device

# Program the device
puts "Programming FPGA with: $bitstream_file"
set_property PROGRAM.FILE $bitstream_file $device
program_hw_devices $device

# Verify
refresh_hw_device $device

puts "Programming completed successfully!"

# Close hardware manager
close_hw_target
disconnect_hw_server
close_hw_manager
