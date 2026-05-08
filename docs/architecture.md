# Template Architecture

## How it works

```
config.tcl
  BOARD = "cmod_a7"
  PROJECT_NAME, TOP_MODULE, SOURCE_FILES, CONSTRAINT_FILES, BUILD_DIR

build.ps1  (dispatcher)
  |-- build.tcl     --> reads config.tcl + boards/<BOARD>/board.tcl
  |-- program.tcl   --> reads config.tcl
  |-- flash.tcl     --> reads config.tcl + boards/<BOARD>/board.tcl
  `-- simulate.tcl  --> hardcoded to reaction_game_tb (edit as needed)
```

## Directory layout

```
.
├── boards/                   # Board definitions
│   ├── cmod_a7/
│   │   ├── board.tcl         # FPGA part, clock, flash params
│   │   └── constraints.xdc   # Full board pin reference
│   ├── basys3/
│   ├── arty_a7_35t/
│   └── nexys_a7_100t/
├── constraints/              # Project-specific pin constraints
│   ├── DSL_Starter_Kit.xdc   # CMOD A7 + DSL expansion board
│   ├── CMODA7_Constrain.xdc  # CMOD A7 bare board
│   └── recorder.xdc          # Active project constraints
├── scripts/
│   ├── setup.py              # Setup GUI
│   ├── config.tcl            # Project configuration (edit this)
│   ├── build.tcl             # Vivado: create project, synth, impl, bitstream
│   ├── program.tcl           # Vivado: JTAG programming (volatile)
│   ├── flash.tcl             # Vivado: configuration flash (non-volatile)
│   ├── simulate.tcl          # Vivado: behavioral simulation
│   └── build.ps1             # PowerShell dispatcher
├── src/                      # Public template examples (git-tracked)
├── src_main/                 # Personal projects (git-ignored)
├── testbench/                # Simulation testbenches
├── docs/                     # Extended documentation
└── .vscode/
    ├── tasks.json            # VS Code build tasks
    ├── settings.json         # File associations and linting
    └── extensions.json       # Recommended extensions
```

## Configuration loading order

1. `build.ps1` calls Vivado in batch mode with a Tcl script
2. Tcl script sources `scripts/config.tcl` — sets user variables
3. Tcl script sources `boards/$BOARD/board.tcl` — sets hardware variables
4. Build proceeds using the combined variable set

Board variables (`PART_NAME`, `CFGMEM_*`) override nothing in config.tcl — they are in separate namespaces. Both files use `set`, so the board file must be sourced after config to have effect.

## Private vs public files

- `src/` — template examples, committed to git
- `src_main/` — git-ignored; all personal project Verilog goes here
- The build system reads from `src_main/` by default (set in `build.tcl`)

To build a template example from `src/` temporarily:
In `build.tcl` line 2, change `src_main` to `src`.

## Build output

Vivado writes all generated files to `BUILD_DIR` (default: `C:/fpga_build`).
This path is outside OneDrive by design to avoid file-locking issues during synthesis.

The build directory is never committed to git.

## Extending the template

| Goal | What to change |
|------|----------------|
| New board | Add `boards/<name>/board.tcl` and `constraints.xdc` |
| New synthesis strategy | Edit `SYNTH_STRATEGY` in `config.tcl` |
| Config-driven simulation | Edit `simulate.tcl` to read `TOP_MODULE` from config |
| Extra build steps | Append Tcl commands to `build.tcl` after `wait_on_run impl_1` |
