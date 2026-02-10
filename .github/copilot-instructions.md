# Verilog FPGA Development with Vivado ML Edition

## Project Context
This is a Verilog hardware development project targeting the CMOD A7 FPGA board using Xilinx Vivado ML Edition.

## Coding Guidelines
- Follow Verilog-2001 standard
- Use meaningful signal and module names
- Include clear comments for complex logic
- Keep modules focused and reusable
- Use non-blocking assignments (<=) for sequential logic
- Use blocking assignments (=) for combinational logic

## Project Structure
- `src/`: Verilog source files (.v)
- `constraints/`: XDC constraint files for pin mapping
- `testbench/`: Simulation and testbench files
- `scripts/`: TCL scripts for Vivado automation
- `build/`: Generated build artifacts (git-ignored)

## Development Workflow
1. Write Verilog in `src/`
2. Define pin constraints in `constraints/`
3. Run synthesis, implementation, and bitstream generation using build script
4. Program CMOD A7 board via USB-JTAG
