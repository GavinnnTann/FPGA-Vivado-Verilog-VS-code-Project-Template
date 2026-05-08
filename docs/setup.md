# Setup Guide

## Prerequisites

- **Xilinx Vivado ML Edition** 2023.1 or later — [download](https://www.xilinx.com/support/download.html)
- **Python 3.10+** (for the setup GUI — `tkinter` is included in the standard library)
- **VS Code** with recommended extensions (install when prompted on first open)

## First-time setup

### 1. Run the setup GUI

```powershell
python scripts/setup.py
```

Or from VS Code: `Ctrl+Shift+P` > `Tasks: Run Task` > `Configure Project (Setup GUI)`

### 2. Workspace Setup tab — configure Vivado path

Click **Auto-detect**. If Vivado is found, click **Save to build.ps1**.

If auto-detect fails, click **Browse** and navigate to `vivado.bat` manually:

```
C:\Xilinx\Vivado\<version>\bin\vivado.bat
```

### 3. New Project tab — scaffold your first project

Fill in:
- **Project name** — used for the Vivado project directory
- **Top module** — must match the `module` name in your Verilog file

Select your board from the **Board** dropdown in Project Config, then click **Create Project**.

This creates:
- `src_main/<module>.v` — starter Verilog with clock and LED port
- `constraints/<project>.xdc` — pin constraint stub copied from `boards/<board>/constraints.xdc`
- Updates `scripts/config.tcl` automatically

### 4. Validate tab — confirm everything is ready

Click **Run Validation**. All items should show `[PASS]`.

### 5. Build

Press `Ctrl+Shift+B` or run task `Build FPGA Design`.

---

## Manual configuration (without the GUI)

Edit `scripts/config.tcl` directly. The only variables you need to change for a new project:

```tcl
set PROJECT_NAME "my_project"
set TOP_MODULE   "my_top"
set BOARD        "cmod_a7"          # see boards/ for available boards
set SOURCE_FILES [list "my_top.v"]
set CONSTRAINT_FILES [list "my_project.xdc"]
```

Vivado path is in `scripts/build.ps1`:

```powershell
[string]$VivadoPath = "C:\Xilinx\Vivado\2023.1\bin\vivado.bat"
```

---

## Troubleshooting

**Vivado not found by auto-detect**
- Check that Vivado is installed under `C:\Xilinx\Vivado\` or `C:\AMD\Vivado\`
- Browse manually to the `vivado.bat` file

**Board not appearing in dropdown**
- Confirm `boards/<name>/board.tcl` exists
- Click "Reload from file" in the GUI

**Board not detected (JTAG)**
- Install Digilent USB cable drivers
- Check Device Manager for the JTAG device
- Try a different USB cable or port
