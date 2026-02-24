# ===================================================================
# FPGA Project Configuration File
# ===================================================================
# Edit this file when starting a new project. All build scripts will
# automatically use these settings.
# ===================================================================

# Project name (will be used for Vivado project directory name)
set PROJECT_NAME "cmod_a7_project"

# Top module name (the main Verilog module to synthesize)
set TOP_MODULE "s7seg"

# FPGA part number
# Default: xc7a35tcpg236-1 (CMOD A7)
# Change this if using a different FPGA board
set PART_NAME "xc7a35tcpg236-1"

# Source files configuration
# Option 1: Specific file (recommended for single-file projects)
# set SOURCE_FILES [list "7seg.v"]

# Option 2: Multiple specific files (uncomment and edit as needed)
set SOURCE_FILES [list "7seg_top.v" "7seg.v"]

# Option 3: All .v files in src/ (uncomment to use all Verilog files)
# set SOURCE_FILES "*.v"

# Constraint files configuration
# Option 1: Use all XDC files in constraints/ directory (default)
set CONSTRAINT_FILES "*.xdc"

# Option 2: Specific constraint file (uncomment and edit as needed)
# set CONSTRAINT_FILES [list "DSL_Starter_Kit.xdc"]

# ===================================================================
# Advanced Settings (usually don't need to change)
# ===================================================================

# Build output directory name (relative to project root)
set BUILD_DIR "build"

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
