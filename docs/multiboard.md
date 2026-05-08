# Multi-Board Support

## Supported boards

| Board | Directory | Part | Clock |
|-------|-----------|------|-------|
| Digilent CMOD A7-35T | `boards/cmod_a7/` | xc7a35tcpg236-1 | 12 MHz |
| Digilent Basys3 | `boards/basys3/` | xc7a35tcpg236-1 | 100 MHz |
| Digilent Arty A7-35T | `boards/arty_a7_35t/` | xc7a35ticsg324-1L | 100 MHz |
| Digilent Nexys A7-100T | `boards/nexys_a7_100t/` | xc7a100tcsg324-1 | 100 MHz |

## Switching boards

**Option A — Setup GUI:**
Open the `Project Config` tab, select a board from the dropdown, click `Save config.tcl`.

**Option B — Manual:**
In `scripts/config.tcl`, change the `BOARD` variable:

```tcl
set BOARD "basys3"
```

The build scripts automatically load the matching `boards/<name>/board.tcl`, which provides the FPGA part number, clock parameters, and flash programming settings.

## Board file structure

```
boards/
  cmod_a7/
    board.tcl           # FPGA part, clock, flash parameters
    constraints.xdc     # Reference pin map for this board
  basys3/
    board.tcl
    constraints.xdc
  ...
```

### board.tcl variables

| Variable | Example | Purpose |
|----------|---------|---------|
| `BOARD_DISPLAY_NAME` | `"Digilent CMOD A7-35T"` | Human-readable name |
| `PART_NAME` | `"xc7a35tcpg236-1"` | Vivado FPGA part string |
| `CLOCK_MHZ` | `12` | Board clock frequency |
| `CLOCK_PERIOD_NS` | `83.33` | Clock period for constraints |
| `CLOCK_HALF_NS` | `41.66` | Half-period for `create_clock` |
| `CLOCK_PIN` | `"L17"` | Package pin for the clock |
| `CFGMEM_CANDIDATES` | `[list "mx25l3273f-spi-x1_x2_x4" ...]` | Ordered list of flash parts to try |
| `CFGMEM_SIZE_MB` | `4` | Flash size in megabytes |
| `CFGMEM_INTERFACE` | `"SPIx1"` | SPI interface width for write_cfgmem |

## Adding a new board

1. Create a directory: `boards/<your_board>/`

2. Create `boards/<your_board>/board.tcl`:

```tcl
set BOARD_DISPLAY_NAME "Your Board Name"
set PART_NAME          "xc7aXXXXXXX-X"
set CLOCK_MHZ          100
set CLOCK_PERIOD_NS    10.00
set CLOCK_HALF_NS      5.00
set CLOCK_PIN          "E3"

set CFGMEM_CANDIDATES [list \
    "s25fl128sxxxxxx0-spi-x1_x2_x4" \
    "mt25ql128-spi-x1_x2_x4"        \
    "s25fl128*spi*"                  \
]
set CFGMEM_SIZE_MB  16
set CFGMEM_INTERFACE "SPIx1"
```

3. Create `boards/<your_board>/constraints.xdc` with the board's pin map (use an existing file as a template).

4. Set `BOARD "<your_board>"` in `config.tcl` or select it in the setup GUI.

### Finding the correct cfgmem part

If flash programming fails with "No cfgmem part matched", run this in Vivado's Tcl console after connecting to the board:

```tcl
get_cfgmem_parts *spi*
```

Add the matching part name as the first entry in `CFGMEM_CANDIDATES`.

## Using board reference constraints

Each board's `constraints.xdc` lists all available pins, all commented out. When scaffolding a new project (New Project tab or manually), copy the relevant lines and uncomment them.

The active constraint file for your project lives in `constraints/` — it's a project-specific file separate from the board reference.
