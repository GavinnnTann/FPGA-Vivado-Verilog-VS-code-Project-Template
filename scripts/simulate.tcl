# TCL script for Vivado Simulation
# Simulates reaction_game module with testbench

# Set project paths
set script_dir [file dirname [file normalize [info script]]]
set project_dir [file normalize "$script_dir/../build"]
set src_dir [file normalize "$script_dir/../src"]
set tb_dir [file normalize "$script_dir/../testbench"]
set sim_dir [file normalize "$script_dir/../build/sim"]

# Create simulation directory
file mkdir $sim_dir

puts "=== Starting Vivado Simulation Setup ==="
puts "Source directory: $src_dir"
puts "Testbench directory: $tb_dir"
puts "Simulation directory: $sim_dir"

# Create simulation project
set project_name "reaction_game_sim"
create_project $project_name $sim_dir -part xc7a35tcpg236-1 -force

# Add design files
puts "\nAdding design files..."
set design_file [file normalize "$src_dir/reaction_game.v"]
add_files $design_file
puts "Added: $design_file"

# Add testbench files
puts "\nAdding testbench files..."
set tb_file [file normalize "$tb_dir/reaction_game_tb.v"]
add_files -fileset sim_1 $tb_file
puts "Added: $tb_file"

# Set testbench as top module
set_property top reaction_game_tb [get_filesets sim_1]
update_compile_order -fileset sim_1

puts "\n=== Running Behavioral Simulation ==="

# Launch simulation
launch_simulation -mode behavioral

# Run simulation for specified time
puts "\nRunning simulation..."
run 10000us  # Run for 10 milliseconds (enough to see countdown start)

puts "\n=== Simulation Complete ==="
puts "Waveform saved. You can now:"
puts "  1. View signals in the waveform window"
puts "  2. Add more signals to watch"
puts "  3. Run longer with 'run <time>'"
puts "  4. Restart with 'restart'"

# Add key signals to waveform automatically
add_wave {{/reaction_game_tb/uut/state}}
add_wave {{/reaction_game_tb/uut/led}}
add_wave {{/reaction_game_tb/sw}}
add_wave {{/reaction_game_tb/key0}}
add_wave {{/reaction_game_tb/uut/countdown_value}}
add_wave {{/reaction_game_tb/uut/elapsed_cs}}
add_wave {{/reaction_game_tb/uut/target_pattern}}
add_wave {{/reaction_game_tb/seg}}
add_wave {{/reaction_game_tb/hex}}

puts "\nKey signals added to waveform viewer"
puts "Use Vivado GUI to explore waveforms interactively"
