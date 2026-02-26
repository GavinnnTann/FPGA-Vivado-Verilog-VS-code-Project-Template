`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench: fft_512_tb
// Description: Validates FFT engine correctness using known input signals.
//              Test 1: DC input → all energy in bin 0
//              Test 2: Impulse → flat spectrum
//              Test 3: 1 kHz sine wave → peak at bin ~11 (Fs=46875, N=512)
//              Exports FFT output for external comparison (Python/MATLAB).
//////////////////////////////////////////////////////////////////////////////////

module fft_512_tb;

    // ---------------------------------------------------------------
    // Clock: 12 MHz
    // ---------------------------------------------------------------
    reg clk = 1'b0;
    always #41.667 clk = ~clk;

    // ---------------------------------------------------------------
    // DUT signals
    // ---------------------------------------------------------------
    reg         rst       = 1'b1;
    reg         start     = 1'b0;
    reg  [23:0] in_data   = 24'd0;
    reg         in_valid  = 1'b0;
    reg  [8:0]  in_index  = 9'd0;
    wire        busy;
    wire        done;
    reg  [8:0]  out_addr  = 9'd0;
    wire [23:0] out_re;
    wire [23:0] out_im;

    // ---------------------------------------------------------------
    // DUT
    // ---------------------------------------------------------------
    fft_512 uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .in_data(in_data),
        .in_valid(in_valid),
        .in_index(in_index),
        .busy(busy),
        .done(done),
        .out_addr(out_addr),
        .out_re(out_re),
        .out_im(out_im)
    );

    // ---------------------------------------------------------------
    // Sine wave LUT for test 3 (1 kHz at Fs=46875 Hz)
    // Bin = round(f * N / Fs) = round(1000 * 512 / 46875) ≈ 10.92 → bin 11
    // ---------------------------------------------------------------
    // Pre-compute 512 samples of sin(2*pi*1000*n/46875) scaled to 24-bit
    // Amplitude: 2^22 = 4194304 (half scale to avoid overflow)
    integer n;
    reg signed [23:0] sine_samples [0:511];

    // Simple sine approximation via DPI or pre-loaded
    // For simulation, use $sin via real arithmetic
    real pi_val;
    real angle;
    real sine_val;

    initial begin
        pi_val = 3.14159265358979;
        for (n = 0; n < 512; n = n + 1) begin
            angle = 2.0 * pi_val * 1000.0 * n / 46875.0;
            sine_val = $sin(angle);
            sine_samples[n] = $rtoi(sine_val * 4194304.0);  // scale to 24-bit range
        end
    end

    // ---------------------------------------------------------------
    // Tasks
    // ---------------------------------------------------------------

    // Load samples into FFT (bypassing windowing for direct FFT test)
    task load_samples;
        input integer test_type;  // 0=DC, 1=impulse, 2=sine
        integer i;
        begin
            for (i = 0; i < 512; i = i + 1) begin
                @(posedge clk);
                in_index <= i;
                in_valid <= 1'b1;
                case (test_type)
                    0: in_data <= 24'd1000;              // DC
                    1: in_data <= (i == 0) ? 24'd4194304 : 24'd0;  // impulse
                    2: in_data <= sine_samples[i];       // 1 kHz sine
                    default: in_data <= 24'd0;
                endcase
            end
            @(posedge clk);
            in_valid <= 1'b0;
        end
    endtask

    task run_fft;
        begin
            @(posedge clk);
            start <= 1'b1;
            @(posedge clk);
            start <= 1'b0;

            // Wait for FFT to complete
            wait(done == 1'b1);
            @(posedge clk);
            $display("  FFT computation complete");
        end
    endtask

    task read_and_display_fft;
        input integer num_bins;
        integer i;
        reg signed [23:0] re, im;
        reg [47:0] mag_sq;
        begin
            for (i = 0; i < num_bins; i = i + 1) begin
                out_addr <= i;
                @(posedge clk);
                @(posedge clk); // read latency
                re = out_re;
                im = out_im;
                mag_sq = (re * re) + (im * im);
                if (i < 32 || mag_sq > 48'd1000000)  // print first 32 bins + significant ones
                    $display("  Bin[%3d]: Re=%7d, Im=%7d, |X|^2=%0d", i, re, im, mag_sq);
            end
        end
    endtask

    // ---------------------------------------------------------------
    // Test sequence
    // ---------------------------------------------------------------
    initial begin
        $dumpfile("fft_512_tb.vcd");
        $dumpvars(0, fft_512_tb);

        $display("=== FFT 512-Point Testbench ===\n");

        // Reset
        rst = 1'b1;
        #500;
        rst = 1'b0;
        #100;

        // ---- Test 1: DC Input ----
        $display("--- Test 1: DC Input (all samples = 1000) ---");
        load_samples(0);
        run_fft;
        $display("  First 16 bins:");
        read_and_display_fft(16);
        $display("");

        // Reset between tests
        rst = 1'b1; #200; rst = 1'b0; #100;

        // ---- Test 2: Impulse ----
        $display("--- Test 2: Impulse (sample[0]=4194304, rest=0) ---");
        load_samples(1);
        run_fft;
        $display("  First 16 bins:");
        read_and_display_fft(16);
        $display("");

        // Reset between tests
        rst = 1'b1; #200; rst = 1'b0; #100;

        // ---- Test 3: 1 kHz Sine ----
        $display("--- Test 3: 1 kHz Sine Wave (expecting peak at bin ~11) ---");
        load_samples(2);
        run_fft;
        $display("  Bins 0-31 and significant bins:");
        read_and_display_fft(256);
        $display("");

        $display("=== All Tests Complete ===");
        $finish;
    end

    // Timeout
    initial begin
        #50_000_000;  // 50 ms
        $display("TIMEOUT");
        $finish;
    end

endmodule
