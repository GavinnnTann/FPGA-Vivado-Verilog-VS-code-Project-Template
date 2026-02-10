# DSL Starter Kit - Hardware Configuration Reference

## Board Information
- **FPGA Board**: Digilent CMOD A7-35T (xc7a35tcpg236-1)
- **Expansion Board**: DSL (Digital System Lab) Starter Kit
- **Clock**: 12 MHz system clock (pin L17)

---

## Critical Hardware Polarities

### ⚠️ 7-Segment Display Polarity
**IMPORTANT: The DSL Starter Kit uses COMMON-CATHODE displays**

- **Segments (seg[7:0])**: **ACTIVE-HIGH** 
  - `1` = Segment ON
  - `0` = Segment OFF
  - Bit mapping: `{DP, G, F, E, D, C, B, A}`

- **Digit Select (hex[5:0])**: **ACTIVE-LOW**
  - `0` = Digit enabled
  - `1` = Digit disabled
  - Only use hex[3:0] for 4 digits (hex[5:4] should be HIGH/disabled)

#### Correct 7-Segment Patterns (Active-High)
```verilog
// Common-cathode (active-high segments)
4'd0: seg_pattern = 8'b00111111;  // 0
4'd1: seg_pattern = 8'b00000110;  // 1
4'd2: seg_pattern = 8'b01011011;  // 2
4'd3: seg_pattern = 8'b01001111;  // 3
4'd4: seg_pattern = 8'b01100110;  // 4
4'd5: seg_pattern = 8'b01101101;  // 5
4'd6: seg_pattern = 8'b01111101;  // 6
4'd7: seg_pattern = 8'b00000111;  // 7
4'd8: seg_pattern = 8'b01111111;  // 8
4'd9: seg_pattern = 8'b01101111;  // 9
```

### Switches (sw[9:0])
- **Polarity**: Typically **ACTIVE-HIGH** (verify with your board)
- `1` = Switch ON/UP
- `0` = Switch OFF/DOWN

### LEDs (led[9:0])
- **Polarity**: **ACTIVE-HIGH**
- `1` = LED ON
- `0` = LED OFF

### Buttons
- **btn[1:0]** (CMOD A7): Check if pull-up or pull-down
- **key[1:0]** (DSL Kit): Check if pull-up or pull-down

### RGB LED (CMOD A7 Onboard)
- **led0_r, led0_g, led0_b**: **ACTIVE-LOW**
- `0` = LED ON
- `1` = LED OFF

---

## Pin Assignments (DSL_Starter_Kit.xdc)

### Clock
```tcl
clk - Pin L17 (12 MHz)
```

### 7-Segment Display
**Segments (seg[7:0]):**
- seg[7] - B15 (DP/Segment 7)
- seg[6] - K3  (Segment A)
- seg[5] - A14 (Segment B)
- seg[4] - K2  (Segment C)
- seg[3] - J3  (Segment D)
- seg[2] - H1  (Segment E)
- seg[1] - A16 (Segment F)
- seg[0] - J1  (Segment G)

**Digit Select (hex[5:0]):**
- hex[5] - N2 (Digit 5 - leftmost)
- hex[4] - N1 (Digit 4)
- hex[3] - L2 (Digit 3)
- hex[2] - L1 (Digit 2)
- hex[1] - A15 (Digit 1)
- hex[0] - C15 (Digit 0 - rightmost)

### Switches (sw[9:0])
- sw[9] - T2
- sw[8] - W2
- sw[7] - W3
- sw[6] - W5
- sw[5] - U4
- sw[4] - W4
- sw[3] - U2
- sw[2] - U3
- sw[1] - W7
- sw[0] - V8

### LEDs (led[9:0])
- led[9] - T1
- led[8] - U1
- led[7] - V2
- led[6] - V3
- led[5] - V4
- led[4] - V5
- led[3] - U5
- led[2] - W6
- led[1] - U7
- led[0] - U8

### Keys (key[1:0])
- key[0] - N3
- key[1] - P3

### CMOD A7 Onboard (cled[1:0])
- cled[0] - A17 (Bi-color LED)
- cled[1] - C16 (Bi-color LED)

### RGB LED (CMOD A7)
- led0_b - B17 (Blue)
- led0_g - B16 (Green)
- led0_r - C17 (Red)

---

## Timing Constraints

### Clock Constraint
```tcl
create_clock -add -name sys_clk_pin -period 83.33 -waveform {0 41.66} [get_ports {clk}];
```
- Period: 83.33 ns (12 MHz)
- 50% duty cycle

---

## Display Multiplexing Guidelines

### Refresh Rate Recommendations
- **Minimum refresh per digit**: 60 Hz (to avoid flicker)
- **4 digits total**: Need 240 Hz overall refresh rate minimum
- **Recommended**: 1-5 kHz per digit (4-20 kHz total)

### Example Clock Divider (12 MHz input)
```verilog
// 12 MHz / 1024 = ~11.7 kHz refresh rate
// 4 digits = ~2.9 kHz per digit (flicker-free)
reg [9:0] refresh_counter;
wire [1:0] digit_select = refresh_counter[9:8];

always @(posedge clk) begin
    refresh_counter <= refresh_counter + 1;
end
```

---

## Common Issues & Solutions

### Issue: Display shows inverted patterns (e.g., "-.-.-.-." instead of "0000")
**Solution**: Wrong polarity. DSL Kit uses common-cathode (active-high). Invert all segment and digit select logic.

### Issue: Only one digit displays
**Solution**: Missing multiplexing. Need to rapidly cycle through all digits.

### Issue: Display is dim or unreadable
**Solution**: 
1. Check refresh rate (should be >240 Hz total)
2. Verify digit select is actually toggling
3. Check if current-limiting resistors are in circuit

### Issue: Wrong digits lighting up
**Solution**: Verify digit select mapping (hex[0] = rightmost, hex[3] = leftmost for 4-digit display)

### Issue: Segments don't match expected numbers
**Solution**: Verify segment bit mapping: {DP, G, F, E, D, C, B, A}

---

## Code Generation Instructions for AI

When generating Verilog code for this platform:

1. **Always use active-HIGH logic for:**
   - 7-segment segments (seg[7:0])
   - Digit select (hex[5:0])
   - LEDs (led[9:0])

2. **Use active-LOW logic for:**
   - RGB LED on CMOD A7 (led0_r/g/b)

3. **Clock specifications:**
   - Input clock: 12 MHz
   - Always use synchronous design (posedge clk)
   - Include proper clock dividers for visual outputs

4. **7-segment display:**
   - Must implement multiplexing for multiple digits
   - Refresh rate: 1-5 kHz per digit recommended
   - Segment bit order: {DP, G, F, E, D, C, B, A}
   - Use only hex[3:0] for 4-digit displays

5. **Constraint files:**
   - Use `DSL_Starter_Kit.xdc` for expansion board features
   - Use `CMODA7_Constrain.xdc` for basic CMOD A7 only
   - Uncomment only the pins actually used in the design

6. **Top module naming:**
   - Update `scripts/build.tcl` to set correct top module
   - Update bitstream filename in both build.tcl and program.tcl

---

## Build Process

### Standard Build Commands
```powershell
# Clean build directory
.\scripts\build.ps1 -Action clean

# Build only
.\scripts\build.ps1 -Action build

# Program only
.\scripts\build.ps1 -Action program

# Build and program
.\scripts\build.ps1 -Action all
```

### Updating Top Module
Edit `scripts/build.tcl`:
```tcl
set_property top YOUR_MODULE_NAME [current_fileset]
```

Edit `scripts/build.tcl` and `scripts/program.tcl`:
```tcl
set bitstream_file "$project_dir/$project_name.runs/impl_1/YOUR_MODULE_NAME.bit"
```

---

## Testing & Verification

### Basic Functionality Tests
1. **Switches → LEDs**: Map each switch directly to an LED
2. **Counter on display**: Verify all segments work
3. **Switch → Display**: Show switch values in decimal/hex
4. **Button debouncing**: Test button inputs with counters

### Segment Test Pattern
To verify all segments work:
```verilog
// Display "8888" with all decimal points
seg = 8'b01111111;  // All segments ON
hex = 4'b1111;      // All digits ON
```

---

## Additional Resources

- [CMOD A7 Reference Manual](https://digilent.com/reference/programmable-logic/cmod-a7/reference-manual)
- [7-Segment Display Tutorial](https://www.electronics-tutorials.ws/blog/7-segment-display-tutorial.html)
- Constraint files: See `constraints/` folder

---

**Last Updated**: February 5, 2026
**Board Version**: CMOD A7-35T Rev. B + DSL Starter Kit
