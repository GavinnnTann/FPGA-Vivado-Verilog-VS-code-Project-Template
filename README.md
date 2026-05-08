# FPGA Project Template

Verilog + Xilinx Vivado + VS Code. Designed for SUTD 30.110 Digital Systems Lab (CMOD A7), adaptable to other Artix-7 boards.

Most FPGA tutorials teach you how to write Verilog. Very few teach you how to build a scalable FPGA development workflow.

This repository was created to make FPGA development easier to learn, faster to prototype, and simpler to reproduce across projects. Using VS Code, Vivado automation, TCL scripting, and a beginner-friendly setup system, the template provides a modern foundation for building FPGA projects without fighting the tooling ecosystem first.

## Prerequisites

| Dependency | Notes |
|------------|-------|
| [Xilinx Vivado ML Edition 2023.1+](https://www.xilinx.com/support/download.html) | Free WebPACK licence covers all Artix-7 devices used here |
| Python 3.10+ | Standard library only — no pip installs needed. `tkinter` is included in the official Windows installer. |
| [VS Code](https://code.visualstudio.com/) | Open the project folder and accept the "Install recommended extensions" prompt. Key extensions: `mshr-community.veriloghdl`, `leafvmaple.verilog-numeric-formatter`, `ms-vscode.powershell`. |
| Digilent USB cable drivers | Install [Digilent Adept Runtime](https://digilent.com/reference/software/adept/start) so Vivado can see the JTAG adapter. |

## Quick start

```powershell
# 1. Clone and open in VS Code
# 2. Launch the setup GUI
python scripts/setup.py
```

In the GUI:
1. **Workspace Setup** — click Auto-detect, then Save to build.ps1
2. **New Project** — enter project name and top module, click Create Project
3. **Validate** — click Run Validation, confirm all items pass
4. Back in VS Code — press `Ctrl+Shift+B` to build

Full first-time walkthrough: [docs/setup.md](docs/setup.md)

## Supported boards

| Board | Directory | Part | Clock |
|-------|-----------|------|-------|
| Digilent CMOD A7-35T (default) | `boards/cmod_a7/` | xc7a35tcpg236-1 | 12 MHz |
| Digilent Basys3 | `boards/basys3/` | xc7a35tcpg236-1 | 100 MHz |
| Digilent Arty A7-35T | `boards/arty_a7_35t/` | xc7a35ticsg324-1L | 100 MHz |
| Digilent Nexys A7-100T | `boards/nexys_a7_100t/` | xc7a100tcsg324-1 | 100 MHz |

Switch boards by changing `set BOARD "cmod_a7"` in `scripts/config.tcl` or using the setup GUI.

## Project structure

```
.
├── boards/                   # Board definitions (part, clock, flash params, pin reference)
│   ├── cmod_a7/
│   ├── basys3/
│   ├── arty_a7_35t/
│   └── nexys_a7_100t/
├── constraints/              # Project-specific XDC files
├── scripts/
│   ├── setup.py              # Setup GUI — run this first
│   ├── config.tcl            # Project configuration — the only file to edit
│   ├── build.tcl             # Vivado: synthesis, implementation, bitstream
│   ├── program.tcl           # Vivado: JTAG programming (volatile SRAM)
│   ├── flash.tcl             # Vivado: configuration flash (non-volatile)
│   └── build.ps1             # PowerShell dispatcher
├── src/                      # Template example designs (public, git-tracked)
├── src_main/                 # Your projects (git-ignored, private)
├── testbench/                # Simulation testbenches
└── docs/                     # Extended documentation
```

## Common commands

```powershell
.\scripts\build.ps1 -Action build       # synthesise + implement + bitstream
.\scripts\build.ps1 -Action program     # program FPGA SRAM (volatile)
.\scripts\build.ps1 -Action flash       # write configuration flash (non-volatile)
.\scripts\build.ps1 -Action all         # build + program
.\scripts\build.ps1 -Action allflash    # build + flash
.\scripts\build.ps1 -Action clean       # delete build directory
```

## Configuration

All project settings live in `scripts/config.tcl`. After first-time setup you only ever change this file:

```tcl
set PROJECT_NAME "my_project"
set TOP_MODULE   "my_top"
set BOARD        "cmod_a7"
set SOURCE_FILES [list "my_top.v"]
set CONSTRAINT_FILES [list "my_project.xdc"]
```

The build scripts load board parameters (FPGA part, flash chip, clock) automatically from `boards/<BOARD>/board.tcl`.

## Documentation

| Guide | Contents |
|-------|----------|
| [docs/setup.md](docs/setup.md) | First-time setup, GUI walkthrough, troubleshooting |
| [docs/workflow.md](docs/workflow.md) | Build / program / flash workflow, VS Code tasks |
| [docs/multiboard.md](docs/multiboard.md) | Switching boards, adding a new board |
| [docs/architecture.md](docs/architecture.md) | How the template works internally |

## Private projects

Files in `src_main/` are git-ignored. Put personal project Verilog there — it will never be pushed to GitHub. Template examples in `src/` are public.

## License

MIT — see [LICENSE](LICENSE).

---

Created by Gavin Tan, Singapore University of Technology and Design, Electrical Engineering (Product Development) — Digital Systems Lab 2026
