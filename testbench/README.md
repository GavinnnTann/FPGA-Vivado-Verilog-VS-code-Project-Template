# Testbench and Simulation Guide

## Overview
This directory contains testbenches for simulating and verifying Verilog modules before FPGA deployment.

## Available Testbenches

### reaction_game_tb.v
Comprehensive testbench for the reaction game module that tests:
- **Button debouncing** - Key press detection with 20ms debounce
- **State machine** - All 5 states (IDLE → COUNTDOWN → WAIT_RANDOM → GAME_ACTIVE → SHOW_RESULT)
- **Countdown timer** - 3-2-1-0 countdown display
- **LED randomization** - 1-4 random LEDs in scattered patterns
- **Timer accuracy** - Centisecond counting (10ms resolution)
- **Switch matching** - Game completion logic
- **Reset behavior** - Return to IDLE when switches cleared

## Running Simulations

### Option 1: PowerShell Script (Automated)
```powershell
# Run simulation (opens Vivado GUI with waveforms)
.\scripts\build.ps1 -Action simulate
```

### Option 2: Manual Vivado Command
```bash
vivado -mode batch -source scripts/simulate.tcl
```

### Option 3: Vivado GUI (Interactive)
1. Open Vivado GUI
2. **Tools → Run Simulation → Run Behavioral Simulation**
3. Add `testbench/reaction_game_tb.v` as simulation source
4. Add `src/reaction_game.v` as design source
5. Run simulation and view waveforms

## Simulation Output

### Console Output
The testbench prints detailed test results:
```
=== Reaction Game Testbench ===
--- Test 1: IDLE State ---
Time=1000: PASS - LEDs are off in IDLE
--- Test 2: Button Press ---
Time=501000: Button released, should enter COUNTDOWN state
...
```

### Waveform Files
- **Location**: `build/sim/reaction_game_sim.sim/`
- **Format**: `.wdb` (Vivado waveform database)
- **Signals**: State machine, LEDs, switches, timers, display outputs

## Key Signals to Monitor

| Signal | Description |
|--------|-------------|
| `uut.state` | State machine: 0=IDLE, 1=COUNTDOWN, 2=WAIT_RANDOM, 3=GAME_ACTIVE, 4=SHOW_RESULT |
| `led[9:0]` | LED pattern output (target to match) |
| `sw[9:0]` | Switch inputs from testbench |
| `uut.countdown_value` | Current countdown digit (3→2→1→0) |
| `uut.elapsed_cs` | Elapsed time in centiseconds |
| `uut.target_pattern` | Random LED pattern to match |
| `seg[7:0]` | 7-segment display segments |
| `hex[5:0]` | Digit select signals |

## Timescale Notes
- **Clock**: 12 MHz (83.33ns period)
- **Debounce time**: 20ms (240,000 clock cycles)
- **Countdown**: 1 second per digit
- **Random delay**: 0.5-2 seconds
- **Simulation time**: ~10 seconds total (truncated for speed)

## Modifying Testbenches

### Speed Up Simulation
Reduce delay parameters in testbench:
```verilog
#50000000;  // Wait 50ms instead of 3 seconds
```

### Add More Tests
Extend the testbench with additional scenarios:
```verilog
// Test 10: Error case - wrong switch combination
sw = 10'b1111111111;  // Wrong pattern
#100000;
if (uut.state == 3'd3)  // Still in GAME_ACTIVE
    $display("PASS - Game continues with wrong switches");
```

### Custom Signal Monitoring
Add to simulate.tcl:
```tcl
add_wave {{/reaction_game_tb/uut/lfsr}}  # Monitor LFSR random generator
add_wave {{/reaction_game_tb/uut/cs_counter}}  # Monitor centisecond counter
```

## Troubleshooting

### Simulation Hangs
- Check timeout watchdog (10s limit in testbench)
- Verify state machine transitions
- Ensure button press timing is correct

### No Waveform Output
- Check Vivado simulation settings
- Ensure `$dumpfile` and `$dumpvars` are present
- Run from Vivado GUI for interactive debugging

### Unexpected Results
- Compare testbench stimulus timing with actual hardware timing
- Check for race conditions in clock edges
- Verify LFSR initial seed produces expected randomness

## Best Practices

1. **Run simulations before building** - Catch bugs early
2. **Check timing constraints** - Verify critical paths
3. **Test edge cases** - Button glitches, max timer values
4. **Compare with hardware** - Validate simulation accuracy
5. **Document failures** - Track issues for debugging

## Creating New Testbenches

Template structure:
```verilog
`timescale 1ns / 1ps

module my_module_tb;
    // Declare signals
    reg clk;
    reg reset;
    wire [7:0] output_bus;
    
    // Instantiate UUT
    my_module uut (
        .clk(clk),
        .reset(reset),
        .output_bus(output_bus)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #41.667 clk = ~clk;  // 12MHz
    end
    
    // Test stimulus
    initial begin
        $dumpfile("my_module.vcd");
        $dumpvars(0, my_module_tb);
        
        reset = 1;
        #1000;
        reset = 0;
        
        // Your tests here
        
        #1000000;
        $finish;
    end
endmodule
```
