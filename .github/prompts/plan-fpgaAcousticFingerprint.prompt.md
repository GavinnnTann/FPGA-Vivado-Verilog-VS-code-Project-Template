# FPGA Acoustic Fingerprint Device — Implementation Plan

## INMP441 + CMOD A7 | Real-Time Spectral Feature Extraction

---

## Architecture Summary

| Parameter | Value |
|---|---|
| System clock | 12 MHz (L17) |
| I2S SCK | 3 MHz (12 MHz / 4) |
| Sample rate (Fs) | 46,875 Hz |
| Bit depth | 24-bit signed PCM |
| FFT size | 512-point radix-2 DIT |
| Frequency resolution | ~91.6 Hz/bin |
| Nyquist | ~23.4 kHz |
| Frame period | ~10.9 ms (~91 FPS) |
| UART baud | 115200 (8N1) |
| Est. BRAMs | ~8 of 50 (16%) |
| Est. DSP48 | 4–6 of 90 (5–7%) |

---

## Pin Assignments (Pmod JA for I2S)

The **Pmod JA header** provides grouped signal pins plus VCC/GND — ideal for wiring to an INMP441 breakout with 5 jumper wires:

| INMP441 Pin | FPGA Port | Pmod JA Pin | Package Pin | Direction |
|---|---|---|---|---|
| SCK | `i2s_sck` | JA[1] | G17 | FPGA → Mic |
| WS | `i2s_ws` | JA[2] | G19 | FPGA → Mic |
| SD | `i2s_sd` | JA[3] | N18 | Mic → FPGA |
| VDD | — | JA pin 6 | VCC 3.3V | Power |
| GND + L/R | — | JA pin 5 | GND | Ground (L/R=GND → left ch) |

Additional pins:

| Function | Port | Pin | Notes |
|---|---|---|---|
| Clock | `clk` | L17 | 12 MHz onboard oscillator |
| UART TX | `uart_tx` | J18 | FPGA → PC via USB-UART bridge |
| Status LED | `led` | A17 | Heartbeat / processing indicator |
| Button 0 | `btn_start` | A18 | Start/stop capture |
| Button 1 | `btn_reset` | B18 | System reset |

---

## Module Hierarchy

```
acoustic_top
├── i2s_master         — Generates SCK/WS, captures SD, outputs 24-bit PCM samples
├── sample_buffer      — Ping-pong double-buffered BRAM (512 × 24-bit)
├── hann_window        — ROM lookup + DSP48 multiply, applies Hann window to samples
├── fft_512            — 512-point radix-2 DIT in-place FFT
│   ├── butterfly      — Complex butterfly: (a + W·b, a − W·b)
│   └── twiddle_rom    — 256-entry sin/cos ROM (16-bit precision)
├── magnitude          — |X[k]|² = Re² + Im² using DSP48
├── feature_extract    — Band energy accumulator + peak detector + spectral centroid
├── pkt_format         — Frames features into UART packets with header + checksum
└── uart_tx            — 115200 baud 8N1 transmitter
```

---

## Implementation Steps

### Step 1. Create new constraint file

Create `constraints/acoustic_fingerprint.xdc` containing only the pins listed above: 12 MHz clock with `create_clock`, I2S on Pmod JA (G17, G19, N18), UART TX (J18), LED (A17), and two buttons (A18, B18). All `LVCMOS33` I/O standard.

### Step 2. Update build configuration

Edit `scripts/config.tcl`:
- Set `TOP_MODULE` to `"acoustic_top"`
- Change `CONSTRAINT_FILES` to `[list "acoustic_fingerprint.xdc"]` (drop DSL Starter Kit XDC which assigns conflicting pins)
- `SOURCE_FILES "*.v"` already globs `src_main/` — no change needed

### Step 3. Implement I2S master — `src_main/i2s_master.v`

I2S master that acts as clock source to the INMP441:
- Divide 12 MHz by 4 → `i2s_sck` at 3 MHz (toggle a register every 2 system clocks)
- Count 32 SCK cycles per WS half-period → `i2s_ws` toggles to define left/right frames
- On **falling edge** of SCK, shift in `i2s_sd` bits into a 24-bit shift register
- After 24 bits in left channel frame (WS=0), latch output as `sample_data[23:0]` + assert `sample_valid` for one system clock
- Ignore right channel data (INMP441 L/R pin tied to GND = left channel active)
- Use non-blocking assignments throughout; all logic on `posedge clk`

### Step 4. Implement UART transmitter — `src_main/uart_tx.v`

Standard 115200 8N1 UART TX:
- Baud clock: 12,000,000 / 115,200 ≈ 104 system clocks per bit (actual divider = 104, giving 115,385 baud — 0.16% error, well within tolerance)
- Interface: `tx_data[7:0]`, `tx_start` (strobe), `tx_busy` (status), `tx_out` (serial line)
- State machine: IDLE → START_BIT → DATA[0..7] → STOP_BIT → IDLE
- LSB-first data transmission

### Step 5. Implement I2S + UART loopback top — `src_main/acoustic_top.v` (Phase 1 version)

Initial top module connecting `i2s_master` → `uart_tx` for validation:
- Captures I2S samples and sends raw PCM bytes over UART (3 bytes per sample: MSB, MID, LSB)
- Decimation: send every Nth sample to stay within UART bandwidth (at 115200 baud, max ~3840 samples/sec with 3 bytes each)
- LED blinks at sample rate / 2^15 ≈ 1.4 Hz as heartbeat
- This validates I2S timing correctness and basic UART output before adding FFT

### Step 6. Write I2S testbench — `testbench/i2s_master_tb.v`

Simulate INMP441 behavior:
- Generate a model that responds to SCK/WS by shifting out 24-bit test words on SD
- Inject known sample values (e.g., a digital sine wave) and verify `sample_data` / `sample_valid` output
- Check timing: SCK period = 333.3 ns, WS period = 21.33 µs, sample period = 21.33 µs
- Follow existing testbench conventions: `$dumpfile`, `$dumpvars`, `$display` messages, UUT named `uut`

### Step 7. Implement sample buffer — `src_main/sample_buffer.v`

Double-buffered (ping-pong) BRAM:
- Two 512 × 24-bit buffers, each inferred as BRAM
- Write port: accepts `sample_data` + `sample_valid`, auto-increments write address
- When write address reaches 511, swap buffers and assert `frame_ready`
- Read port: provides sequential access for downstream processing
- Handles buffer swap handshake: processing pipeline asserts `frame_done` when finished reading

### Step 8. Implement Hann window — `src_main/hann_window.v`

Apply Hann window to reduce spectral leakage:
- ROM stores 512 pre-computed 16-bit Hann coefficients: $w[n] = 0.5 \times (1 - \cos(2\pi n / 511))$
- Coefficient values scaled to 16-bit unsigned [0, 65535]
- Multiply each 24-bit sample by 16-bit window coefficient using DSP48 → 40-bit product → truncate to 24-bit
- Reads samples sequentially from buffer, outputs windowed samples
- Generate Hann ROM contents as a `$readmemh` file or inline `case` statement

### Step 9. Implement twiddle factor ROM — `src_main/twiddle_rom.v`

Pre-computed complex exponentials for FFT:
- 256 entries (N/2) of 16-bit cosine and 16-bit sine
- $W_N^k = \cos(2\pi k / 512) - j \cdot \sin(2\pi k / 512)$
- Stored as signed 16-bit fixed-point (1.15 format)
- Addressed by twiddle index from FFT controller
- Inferred as distributed ROM or BRAM

### Step 10. Implement butterfly unit — `src_main/butterfly.v`

Complex radix-2 butterfly computation:
- Inputs: complex `a` (ar + j·ai), complex `b` (br + j·bi), twiddle `W` (wr + j·wi)
- Compute `W·b`: real = br·wr − bi·wi, imag = br·wi + bi·wr (4 multiplications via DSP48)
- Output: `A = a + W·b`, `B = a − W·b`
- Pipeline: 3–4 clock stages (multiply → accumulate → add/subtract → output)
- Data width: 16-bit twiddle × 24-bit data → 40-bit product → round/truncate to 24-bit

### Step 11. Implement FFT engine — `src_main/fft_512.v`

512-point radix-2 decimation-in-time FFT:
- 9 stages ($\log_2 512$)
- In-place computation using dual-port BRAM (512 × 48-bit: 24-bit real + 24-bit imaginary)
- Bit-reversal reordering of input samples on write
- FSM controller that iterates through stages and butterfly pairs:
  - For each stage `s` (0..8): butterfly spacing = $2^s$, group size = $2^{s+1}$
  - Address generation: compute paired indices and twiddle index per butterfly
- Reads two complex values from BRAM → passes through `butterfly` → writes results back
- Asserts `fft_done` when all 9 stages complete
- Total computation: ~2,304 butterflies × ~8 cycles ≈ 18,432 clocks (1.5 ms at 12 MHz)

### Step 12. Implement magnitude computation — `src_main/magnitude.v`

Convert complex FFT output to power spectrum:
- Sequentially read 256 bins (only first half — symmetric for real input)
- Compute $|X[k]|^2 = \text{Re}[k]^2 + \text{Im}[k]^2$ using DSP48
- Output: 256 × 32-bit unsigned magnitude values
- Store in BRAM for feature extraction

### Step 13. Implement feature extraction — `src_main/feature_extract.v`

Extract meaningful spectral descriptors:
- **Peak detection**: find bin index with maximum magnitude → dominant frequency = `bin_index × 91.6 Hz`
- **Band energies** (8 bands, logarithmically spaced):
  - Band 0: bins 1–3 (~92–275 Hz) — sub-bass
  - Band 1: bins 4–7 (~367–642 Hz) — bass
  - Band 2: bins 8–15 (~733–1,375 Hz) — low-mid
  - Band 3: bins 16–31 (~1,466–2,841 Hz) — mid
  - Band 4: bins 32–63 (~2,933–5,773 Hz) — high-mid
  - Band 5: bins 64–95 (~5,865–8,705 Hz) — presence
  - Band 6: bins 96–159 (~8,797–14,569 Hz) — brilliance
  - Band 7: bins 160–255 (~14,661–23,372 Hz) — air
- **Spectral centroid**: weighted mean frequency = $\Sigma(f[k] \cdot |X[k]|^2) / \Sigma(|X[k]|^2)$
- All values normalized/scaled to 16-bit for compact transmission

### Step 14. Implement packet formatter — `src_main/pkt_format.v`

Serialize features into UART-ready byte stream:
- Packet structure (~27 bytes):
  - Header: `0xAA 0x55` (2 bytes — sync marker)
  - Frame counter: 2 bytes (increments per FFT frame)
  - Peak bin index: 2 bytes
  - Peak magnitude: 2 bytes
  - 8 band energies: 16 bytes (2 bytes each)
  - Spectral centroid: 2 bytes
  - Checksum: 1 byte (XOR of all payload bytes)
- At 115200 baud: 27 bytes × 10 bits/byte = 270 bit-times = 2.34 ms per packet
- Frame period is 10.9 ms → 23% UART utilization — comfortable margin
- FIFO or shift-register based byte sequencing into `uart_tx`

### Step 15. Integrate full top module — `src_main/acoustic_top.v` (final version)

Wire all modules together in `acoustic_top`:
- `clk`, `btn_start`, `btn_reset` as inputs
- `i2s_sck`, `i2s_ws` as outputs; `i2s_sd` as input
- `uart_tx` as output; `led` as output
- Button debouncing (simple counter-based, ~20 ms)
- Global reset via `btn_reset` or power-on reset counter
- LED status: slow blink = idle, fast blink = capturing, solid = processing
- Pipeline handshake chain: `sample_valid` → `frame_ready` → `window_done` → `fft_done` → `mag_done` → `features_ready` → `tx_start`

### Step 16. Write FFT testbench — `testbench/fft_512_tb.v`

Validate FFT correctness:
- Inject 512 samples of a known sine wave (e.g., 1 kHz → bin 11 at Fs=46,875 Hz)
- Verify peak bin alignment matches expected frequency
- Test with DC input → all energy in bin 0
- Test with impulse → flat spectrum
- Check windowed vs unwindowed leakage behavior
- Export FFT output via `$writememh` for comparison with Python/MATLAB reference

### Step 17. Write system testbench — `testbench/acoustic_top_tb.v`

End-to-end simulation:
- Simulate INMP441 model producing a known tone
- Run full pipeline: I2S → buffer → window → FFT → magnitude → features → UART
- Capture UART output bitstream and decode packets
- Verify packet structure, checksum, and feature values
- Timeout watchdog per existing conventions

---

## Verification Strategy

1. **I2S timing** (Phase 1): Simulate with `i2s_master_tb.v`, verify SCK = 3 MHz, WS period, and sample capture. Then build + program FPGA, connect INMP441, read raw samples via UART in a serial monitor (e.g., PuTTY, RealTerm, or Python `pyserial`)
2. **FFT correctness** (Phase 2): Simulate `fft_512_tb.v` with known tones. Compare output bins against Python `numpy.fft.fft()` reference. Verify peak bin, magnitude scaling, and Hann window leakage suppression
3. **Feature validation** (Phase 3): Full system simulation → decode UART packets → verify band energies and peak frequency against known input. Then on hardware: play a 1 kHz tone into the mic and confirm peak bin ≈ 11 (1 kHz / 91.6 Hz)
4. **Noise floor**: With mic in quiet environment, verify noise floor is below meaningful threshold. Characterize SNR

---

## File Summary

| File | Location | Purpose |
|---|---|---|
| `acoustic_top.v` | `src_main/` | Top-level module |
| `i2s_master.v` | `src_main/` | I2S clock gen + PCM capture |
| `sample_buffer.v` | `src_main/` | Ping-pong 512-sample BRAM |
| `hann_window.v` | `src_main/` | Hann window ROM + multiply |
| `fft_512.v` | `src_main/` | 512-pt radix-2 DIT FFT controller |
| `butterfly.v` | `src_main/` | Complex butterfly unit |
| `twiddle_rom.v` | `src_main/` | Sin/cos twiddle LUT |
| `magnitude.v` | `src_main/` | Power spectrum computation |
| `feature_extract.v` | `src_main/` | Band energy + peak detection |
| `pkt_format.v` | `src_main/` | UART packet framing |
| `uart_tx.v` | `src_main/` | 115200 baud transmitter |
| `acoustic_fingerprint.xdc` | `constraints/` | Pin constraints |
| `i2s_master_tb.v` | `testbench/` | I2S timing validation |
| `fft_512_tb.v` | `testbench/` | FFT correctness tests |
| `acoustic_top_tb.v` | `testbench/` | Full system simulation |
| `config.tcl` | `scripts/` | Updated TOP_MODULE + constraints |

---

## Design Decisions

- **Clock strategy**: Use 12 MHz directly with counter-based I2S clock generation (no MMCM). 12 MHz provides 131K cycles per FFT frame — ample for a sequential radix-2 engine. Avoids clock domain crossing complexity.
- **I2S SCK = 3 MHz** (12/4): Gives Fs = 46,875 Hz. Non-standard but functionally equivalent. Covers full audible range (Nyquist ≈ 23.4 kHz).
- **Pmod JA for I2S**: Provides grouped pins (G17/G19/N18) plus adjacent VCC/GND for clean single-connector wiring to INMP441 breakout.
- **New constraint file**: Dedicated `acoustic_fingerprint.xdc` avoids conflicts with DSL Starter Kit's 35+ pin assignments.
- **In-place radix-2 FFT**: Resource-efficient (~8 BRAMs, 4 DSP48). Fits comfortably in xc7a35t. Chosen over radix-4 (which saves stages but doubles butterfly complexity).
- **Feature-level UART output** (not raw FFT): 27-byte packets at ~91 FPS consume only 23% of UART bandwidth. Keeps serial monitor readable.
- **Phased implementation**: I2S+UART validation first (Step 5), then FFT (Steps 7–12), then features (Steps 13–15). Each phase is independently testable on hardware.
