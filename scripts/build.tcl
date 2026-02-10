# TCL script for Vivado - Build project for CMOD A7
# This script creates a Vivado project, runs synthesis, implementation, and generates bitstream

# Set directory paths (relative to script location)
set script_dir [file dirname [file normalize [info script]]]
set src_dir [file normalize "$script_dir/../src"]
set constraints_dir [file normalize "$script_dir/../constraints"]

# Load project configuration
set config_file [file normalize "$script_dir/config.tcl"]
if {![file exists $config_file]} {
    puts "ERROR: Configuration file not found: $config_file"
    puts "Please create config.tcl in the scripts directory"
    exit 1
}
source $config_file

# Set project directory based on config
set project_dir [file normalize "$script_dir/../$BUILD_DIR"]
set project_name $PROJECT_NAME
set part_name $PART_NAME

# Debug: Print paths
puts "DEBUG: script_dir = $script_dir"
puts "DEBUG: src_dir = $src_dir"
puts "DEBUG: project_dir = $project_dir"

# Create project directory if it doesn't exist
file mkdir $project_dir

# Create project
create_project -force $project_name $project_dir -part $part_name

# Add Verilog source files from configuration
if {[llength $SOURCE_FILES] == 1 && [string match "*\**" $SOURCE_FILES]} {
    # Glob pattern - add all matching files
    puts "Adding source files matching pattern: $SOURCE_FILES"
    set source_file_list [glob -nocomplain $src_dir/$SOURCE_FILES]
    if {[llength $source_file_list] == 0} {
        puts "ERROR: No source files found matching pattern: $SOURCE_FILES"
        exit 1
    }
    add_files $source_file_list
    puts "Added [llength $source_file_list] source file(s)"
} else {
    # Specific file list
    set source_file_list {}
    foreach src_file $SOURCE_FILES {
        set full_path [file normalize "$src_dir/$src_file"]
        if {![file exists $full_path]} {
            puts "ERROR: Source file not found: $full_path"
            exit 1
        }
        lappend source_file_list $full_path
        puts "Adding source file: $full_path"
    }
    add_files $source_file_list
}

# Add constraint files from configuration
if {[llength $CONSTRAINT_FILES] == 1 && [string match "*\**" $CONSTRAINT_FILES]} {
    # Glob pattern
    add_files -fileset constrs_1 [glob -nocomplain $constraints_dir/$CONSTRAINT_FILES]
} else {
    # Specific file list
    foreach const_file $CONSTRAINT_FILES {
        set full_path [file normalize "$constraints_dir/$const_file"]
        if {[file exists $full_path]} {
            add_files -fileset constrs_1 $full_path
        }
    }
}

# Set top module from configuration
set_property top $TOP_MODULE [current_fileset]

# Update compile order
update_compile_order -fileset sources_1

# Run synthesis
puts "Running Synthesis..."
launch_runs synth_1
wait_on_run synth_1
open_run synth_1

# Check for synthesis errors
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "ERROR: Synthesis failed!"
    exit 1
}
puts "Synthesis completed successfully"

# Run implementation
puts "Running Implementation..."
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1

# Check for implementation errors
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "ERROR: Implementation failed!"
    exit 1
}
puts "Implementation completed successfully"

# Open implemented design for reports
open_run impl_1

# Generate timing report
puts "Generating timing report..."
report_timing_summary -file $project_dir/timing_summary.rpt

# Generate utilization report
puts "Generating utilization report..."
report_utilization -file $project_dir/utilization.rpt

# Generate power report
puts "Generating power report..."
report_power -file $project_dir/power.rpt

puts "Bitstream generated: $project_dir/$project_name.runs/impl_1/$TOP_MODULE.bit"
puts "Build completed successfully!"
