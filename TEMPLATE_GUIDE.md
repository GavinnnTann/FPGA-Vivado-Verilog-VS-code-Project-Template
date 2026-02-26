# 🚀 Quick Start Guide - FPGA Project Template

## Starting a New Project

When you want to start a new FPGA project, simply edit the configuration file:

### 📝 Edit `scripts/config.tcl`

This is the **ONLY** file you need to edit for a new project!

```tcl
# 1. Change the project name
set PROJECT_NAME "my_new_project"

# 2. Set your top module name (main Verilog module)
set TOP_MODULE "my_top_module"

# 3. Specify which source files to include
set SOURCE_FILES [list "my_top_module.v"]

# For multiple files:
# set SOURCE_FILES [list "top.v" "counter.v" "display.v"]

# Or include ALL .v files in src_main/:
# set SOURCE_FILES "*.v"

# 4. (Optional) Change FPGA part if using different board
# set PART_NAME "xc7a35tcpg236-1"  # CMOD A7 (default)

# 5. (Optional) Specify constraint files
# set CONSTRAINT_FILES [list "my_constraints.xdc"]
```

### 📂 Add Your Verilog Files

**For Personal Projects (Recommended - Private):**
1. Place your `.v` files in the `src_main/` directory
2. These files are **automatically git-ignored** and won't be pushed to GitHub
3. Perfect for personal projects you want to keep private

**For Template Examples (Public):**
1. Place example `.v` files in the `src/` directory
2. These files are tracked in git and shared publicly
3. Use for reference designs and teaching examples

**Constraint Files:**
- Place your `.xdc` constraint files in the `constraints/` directory

### ▶️ Build and Run

```powershell
# Build the design
.\scripts\build.ps1 -Action build

# Program the FPGA
.\scripts\build.ps1 -Action program

# Or do both at once
.\scripts\build.ps1 -Action all

# Clean build artifacts
.\scripts\build.ps1 -Action clean
```

Or use VS Code tasks:
- Press `Ctrl+Shift+B` to build
- Run task: `Program FPGA` to program the board

## 📋 Configuration Options

### Source Files Options

**Option 1: Single file** (recommended for simple projects)
```tcl
set SOURCE_FILES [list "blink.v"]
```

**Option 2: Multiple specific files**
```tcl
set SOURCE_FILES [list "top.v" "counter.v" "uart.v" "display.v"]
```

**Option 3: All Verilog files** (automatically includes all .v files)
```tcl
set SOURCE_FILES "*.v"
```

### Constraint Files Options

**Option 1: All XDC files** (default)
```tcl
set CONSTRAINT_FILES "*.xdc"
```

**Option 2: Specific constraint file**
```tcl
set CONSTRAINT_FILES [list "DSL_Starter_Kit.xdc"]
```

**Option 3: Multiple constraint files**
```tcl
set CONSTRAINT_FILES [list "pins.xdc" "timing.xdc"]
```

## 🎯 Example Projects

### Example 1: LED Blinker
```tcl
set PROJECT_NAME "led_blinker"
set TOP_MODULE "blink"
set SOURCE_FILES [list "blink.v"]
```

### Example 2: Switch Display
```tcl
set PROJECT_NAME "switch_display_demo"
set TOP_MODULE "switch_display"
set SOURCE_FILES [list "switch_display.v"]
```

### Example 3: Complex Project with Multiple Modules
```tcl
set PROJECT_NAME "uart_system"
set TOP_MODULE "uart_top"
set SOURCE_FILES [list "uart_top.v" "uart_tx.v" "uart_rx.v" "fifo.v"]
```

### Example 4: Include All Source Files
```tcl
set PROJECT_NAME "complete_system"
set TOP_MODULE "system_top"
set SOURCE_FILES "*.v"  # Includes all .v files in src/
```

## 🔧 Different FPGA Boards

If using a different FPGA board, change the part number in config.tcl:

```tcl
# CMOD A7 (default)
set PART_NAME "xc7a35tcpg236-1"

# Basys 3
# set PART_NAME "xc7a35tcpg236-1"

# Nexys A7-100T
# set PART_NAME "xc7a100tcsg324-1"

# Arty A7-35T
# set PART_NAME "xc7a35ticsg324-1L"
```

## ⚠️ Important Notes

1. **Module name must match**: Ensure your `TOP_MODULE` name matches the actual module name in your Verilog file

2. **File paths**: Source files are relative to `src_main/` directory by default (or `src/` for template examples), constraint files relative to `constraints/` directory

3. **Private vs Public**: Files in `src_main/` are git-ignored (private), files in `src/` are public (template examples)

3. **No script editing needed**: After setting up config.tcl, all build scripts automatically use your configuration

4. **Version control**: Commit your config.tcl to track project settings

## 🐛 Troubleshooting
_main/` directory (or `src/` for templates)
- Verify the filename in `SOURCE_FILES` matches exactly (case-sensitive)
- If using template examples, temporarily change `build.tcl` line 4 from `src_main` to `src`
- Check that your .v file exists in the `src/` directory
- Verify the filename in `SOURCE_FILES` matches exactly (case-sensitive)

**Error: Top module not found**
- Ensure `TOP_MODULE` matches the module name in your Verilog file
- Check for typos in the module name

**Build succeeds but wrong module synthesized**
- Verify `TOP_MODULE` is set to your main module name
- Check that the module is present in one of your `SOURCE_FILES`

## 📚 Files Modified by Template System

- ✅ `scripts/config.tcl` - **Edit this for new projects**
- ✅ `scripts/build.tcl` - Uses config (no manual editing needed)
- ✅ `scripts/program.tcl` - Uses config (no manual editing needed)
- ✅ `scripts/build.ps1` - Uses config indirectly (no manual editing needed)

---

Made for SUTD Engineering Product Development Digital Systems Lab (Year 2026)
