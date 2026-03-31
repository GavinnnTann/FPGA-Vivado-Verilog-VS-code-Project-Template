# FPGA Project Template

A reusable, configurable template for FPGA development with Verilog, Xilinx Vivado, and VS Code. Designed for CMOD A7 but easily adaptable to other boards.

## ✨ Features

- **🎯 Centralized Configuration**: Single `config.tcl` file to configure all project settings
- **🤖 Automated Build System**: PowerShell and TCL scripts for synthesis, implementation, and programming
- **📦 Multi-Board Support**: Easy switching between FPGA boards
- **🔧 VS Code Integration**: Tasks for one-click builds and programming
- **📚 Example Projects**: LED blinker, switch display, and reaction game included
- **🔒 Private Project Folder**: Keep personal projects private with `src_main/` (git-ignored)

## 📁 Project Structure

```
.
├── .github/
│   └── copilot-instructions.md    # GitHub Copilot instructions
├── .vscode/
│   ├── extensions.json             # Recommended VS Code extensions
│   ├── settings.json               # Workspace settings
│   └── tasks.json                  # Build tasks
├── src/                            # 📚 Template examples (public)
│   ├── blink.v                     # Example: LED blink module
│   ├── switch_display.v            # Example: Switch to LED mapping
│   └── reaction_game.v             # Example: Reaction game
├── src_main/                       # 🔒 YOUR PROJECTS (git-ignored, private)
│   └── README.md                   # Instructions for personal projects
├── constraints/
│   └── cmod_a7.xdc                 # Pin constraints for CMOD A7
├── testbench/
│   └── (simulation testbenches)
├── scripts/
│   ├── config.tcl                  # ⚙️ PROJECT CONFIGURATION (edit this!)
│   ├── build.tcl                   # Vivado synthesis & implementation
│   ├── program.tcl                 # FPGA programming script
│   └── build.ps1                   # PowerShell automation script
├── build/                          # Generated artifacts (git-ignored)
├── .gitignore
├── TEMPLATE_GUIDE.md               # Template usage guide
└── README.md
```

## 🚀 Quick Start

### Prerequisites

1. **Xilinx Vivado ML Edition** (2023.1 or later)
   - Download from [Xilinx website](https://www.xilinx.com/support/download.html)
   - Install with CMOD A7 board support

2. **VS Code Extensions** (Auto-recommended)
   - **mshr-h.veriloghdl** - Verilog HDL/SystemVerilog syntax highlighting
   - **teros-technology.teroshdl** - Advanced HDL support, linting, and documentation

3. **CMOD A7 Board** (or compatible)
   - Default: `xc7a35tcpg236-1`
   - Connect via USB (provides both power and JTAG)

### Installation

1. Clone or download this project
2. Open the folder in VS Code
3. Install recommended extensions when prompted
4. **Configure your project** by editing `scripts/config.tcl`:
   ```tcl
   set PROJECT_NAME "my_project"
   set TOP_MODULE "my_top_module"
   set SOURCE_FILES [list "my_top_module.v"]
   ```
5. Update Vivado path in `scripts/build.ps1` if needed (default: `C:\Xilinx\Vivado\2023.1\bin\vivado.bat`)

> 📖 See [TEMPLATE_GUIDE.md](TEMPLATE_GUIDE.md) for detailed configuration options

## � Private Projects vs Public Template

This template uses a **dual-folder approach** to let you maintain public template examples while keeping your personal projects private:

- **`src/`** - Template examples (public, tracked in git)
  - Contains reference designs: `blink.v`, `switch_display.v`, `reaction_game.v`, etc.
  - These files are shared publicly as examples for others to learn from
  
- **`src_main/`** - Your personal projects (private, git-ignored)
  - **All files here are automatically excluded from git**
  - Place your custom Verilog projects here
  - Build system is pre-configured to use this folder

### Using Personal Projects Folder

1. **Create your Verilog files in `src_main/`:**
   ```powershell
   # Copy a template example to get started
   Copy-Item src\blink.v src_main\my_project.v
   ```

2. **Edit `scripts/config.tcl`:**
   ```tcl
   set PROJECT_NAME "my_project"
   set TOP_MODULE "my_top"
   set SOURCE_FILES [list "my_project.v"]
   # Or use "*.v" to include all files in src_main/
   ```

3. **Build and program normally** - everything already points to `src_main/`

### Switching to Template Examples

To build and test template examples from `src/`:
1. Temporarily edit `scripts/build.tcl` line 4: change `src_main` back to `src`
2. Update `config.tcl` to reference the template module
3. Build and test
4. Switch back to `src_main` for your personal work

> 💡 **Tip:** Your personal projects in `src_main/` will never be pushed to GitHub, keeping your work private while you maintain and share the template!

## �🔧 Development Workflow

### Option 1: Using VS Code Tasks (Recommended)

1. **Build the design:**
   - Press `Ctrl+Shift+B` or run task: `Terminal > Run Build Task`
   - Builds synthesis, implementation, and generates bitstream

2. **Program the FPGA:**
   - Press `Ctrl+Shift+P` → `Tasks: Run Task` → `Program FPGA`
   - Programs the connected CMOD A7 board

3. **Build and Program:**
   - Run task: `Build and Program FPGA`
   - Does both in one step

4. **Clean build artifacts:**
   - Run task: `Clean Build`

### Option 2: Using PowerShell Script

```powershell
# Build only
.\scripts\build.ps1 -Action build

# Program only (requires existing build)
.\scripts\build.ps1 -Action program

# Build and program
.\scripts\build.ps1 -Action all

# Clean build directory
.\scripts\build.ps1 -Action clean

# Specify custom Vivado path
.\scripts\build.ps1 -Action build -VivadoPath "C:\Xilinx\Vivado\2023.2\bin\vivado.bat"
```

### Option 3: Direct Vivado Commands

```powershell
# Run synthesis and implementation
vivado -mode batch -source scripts/build.tcl

# Program FPGA
vivado -mode batch -source scripts/program.tcl
```

## 📝 Writing Verilog Code

### Coding Guidelines

- Follow **Verilog-2001** standard
- Use **non-blocking assignments** (`<=`) for sequential logic
- Use **blocking assignments** (`=`) for combinational logic
- Add meaningful comments
- Keep modules focused and reusable

### Example: LED Blink Module

The included [src/blink.v](src/blink.v) demonstrates:
- Clock divider for 12MHz input clock
- Simple counter-based state machine
- Active-low reset handling
- LED output control

### Starting a New Project

1. **Edit `scripts/config.tcl`** (this is the ONLY file you need to edit!):
   ```tcl
   set PROJECT_NAME "my_new_project"
   set TOP_MODULE "my_top_module"
   set SOURCE_FILES [list "my_top_module.v"]
   # Or use all .v files: set SOURCE_FILES "*.v"
   ```

2. Create `.v` files in `src/` directory

3. Add pin constraints in `constraints/` directory

4. Build and program using the workflow below

> 💡 **No need to edit build scripts!** All configuration is centralized in `config.tcl`

## 🔌 CMOD A7 Pin Mapping

Key pins configured in [constraints/cmod_a7.xdc](constraints/cmod_a7.xdc):

| Signal | Pin  | Description           |
|--------|------|-----------------------|
| clk    | L17  | 12 MHz system clock   |
| rst_n  | A18  | Button 0 (reset)      |
| led    | A17  | RGB LED (blue channel)|

See constraint file for complete pinout including:
- RGB LED channels (R, G, B)
- Buttons (BTN0, BTN1)
- Pmod header JA pins

## 🧪 Simulation & Testing

Create testbenches in `testbench/` directory:

```verilog
`timescale 1ns / 1ps

module blink_tb;
    reg clk, rst_n;
    wire led;
    
    blink uut (
        .clk(clk),
        .rst_n(rst_n),
        .led(led)
    );
    
    initial begin
        clk = 0;
        forever #41.67 clk = ~clk;  // 12MHz
    end
    
    initial begin
        rst_n = 0;
        #100 rst_n = 1;
        #100000 $finish;
    end
endmodule
```

## 📊 Generated Reports

After building, find reports in `build/`:
- `timing_summary.rpt` - Timing analysis
- `utilization.rpt` - Resource utilization
- `power.rpt` - Power estimation

## 🛠️ Troubleshooting

### Vivado Not Found
Update the path in `scripts/build.ps1`:
```powershell
$VivadoPath = "C:\Xilinx\Vivado\YOUR_VERSION\bin\vivado.bat"
```

### Board Not Detected
1. Install Xilinx USB Cable drivers
2. Check Device Manager for "Digilent USB Device"
3. Try different USB port/cable

### Synthesis Errors
- Check Verilog syntax
- Verify module names match between files
- Review `build/*.log` files

### Timing Violations
- Check `timing_summary.rpt`
- Add timing constraints in XDC file
- Optimize critical paths

## 🎓 Using This Template

See **[TEMPLATE_GUIDE.md](TEMPLATE_GUIDE.md)** for comprehensive documentation on:
- Configuration options
- Example project setups
- Multi-board support
- Troubleshooting

## 📚 Resources

- [CMOD A7 Reference Manual](https://digilent.com/reference/programmable-logic/cmod-a7/reference-manual)
- [Vivado Design Suite User Guide](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2023_2/ug893-vivado-ide.pdf)
- [Verilog Quick Reference](https://web.stanford.edu/class/ee183/handouts_win2003/VerilogQuickRef.pdf)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Free to use for educational and commercial purposes.

## 🤝 Contributing

Feel free to submit issues, fork the repository, and create pull requests for improvements.

---

**Created by Gavin Tan SUTD-EPD**
**Made for SUTD Engineering Product Development Digital Systems Lab (Year 2026)**
