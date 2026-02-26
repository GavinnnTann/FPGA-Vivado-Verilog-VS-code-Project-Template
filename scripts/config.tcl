# ===================================================================
# FPGA Project Configuration File
# ===================================================================
# Edit this file when starting a new project. All build scripts will
# automatically use these settings.
# ===================================================================

# Project name (will be used for Vivado project directory name)
set PROJECT_NAME "cmod_a7_project"

# Top module name (the main Verilog module to synthesize)
# IMPORTANT: Change this to match your top-level module in src_main/
set TOP_MODULE "Stopwatch"

# FPGA part number
# Default: xc7a35tcpg236-1 (CMOD A7)
# Change this if using a different FPGA board
set PART_NAME "xc7a35tcpg236-1"

# Source files configuration
# NOTE: Files are now loaded from src_main/ (for personal projects)
#       Template examples remain in src/ folder
# Option 1: Specific file (recommended for single-file projects)
# set SOURCE_FILES [list "my_module.v"]

# Option 2: Multiple specific files (uncomment and edit as needed)
# set SOURCE_FILES [list "top_module.v" "submodule.v"]

# Option 3: All .v files in src_main/ (uncomment to use all Verilog files)
# set SOURCE_FILES "*.v"
set SOURCE_FILES [list "Stopwatch.v"]

# Constraint files configuration
# Option 1: Use all XDC files in constraints/ directory (default)
# set CONSTRAINT_FILES "*.xdc"

# Option 2: Specific constraint file (uncomment and edit as needed)
set CONSTRAINT_FILES [list "stopwatch.xdc"]

# ===================================================================
# Advanced Settings (usually don't need to change)
# ===================================================================

# Build output directory name
# Using a local path outside OneDrive to avoid file-locking issues
set BUILD_DIR "C:/fpga_build"

# Synthesis strategy (default: Vivado Synthesis Defaults)
# Options: "Vivado Synthesis Defaults", "Flow_PerfOptimized_high", etc.
set SYNTH_STRATEGY "Vivado Synthesis Defaults"

# Implementation strategy (default: Vivado Implementation Defaults)
# Options: "Vivado Implementation Defaults", "Performance_ExplorePostRoutePhysOpt", etc.
set IMPL_STRATEGY "Vivado Implementation Defaults"

# ===================================================================
# DO NOT EDIT BELOW THIS LINE
# ===================================================================
puts "INFO: Loaded configuration for project: $PROJECT_NAME"
puts "INFO: Top module: $TOP_MODULE"
puts "INFO: Target device: $PART_NAME"
