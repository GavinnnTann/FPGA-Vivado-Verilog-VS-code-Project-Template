`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench: acoustic_top_tb
// Description: End-to-end system testbench for the acoustic fingerprint device.
//              Simulates INMP441 producing a known 1 kHz tone.
//              Verifies full pipeline: I2S → buffer → window → FFT → magnitude
//              → features → packet → UART.
//              Captures UART output and decodes packets.
//////////////////////////////////////////////////////////////////////////////////

module acoustic_top_tb;

    // ---------------------------------------------------------------
    // Clock: 12 MHz
    // ---------------------------------------------------------------
    reg clk = 1'b0;
    always #41.667 clk = ~clk;

    // ---------------------------------------------------------------
    // DUT signals
    // ---------------------------------------------------------------
    reg  btn_start = 1'b0;
    reg  btn_reset = 1'b1;
    wire i2s_sck;
    wire i2s_ws;
    reg  i2s_sd = 1'b0;
    wire uart_tx;
    wire led;

    // ---------------------------------------------------------------
    // DUT
    // ---------------------------------------------------------------
    acoustic_top uut (
        .clk(clk),
        .btn_start(btn_start),
        .btn_reset(btn_reset),
        .i2s_sck(i2s_sck),
        .i2s_ws(i2s_ws),
        .i2s_sd(i2s_sd),
        .uart_tx(uart_tx),
        .led(led)
    );

    // ---------------------------------------------------------------
    // Simulated INMP441 — generates 1 kHz tone
    // Fs = 46875 Hz, 24-bit, amplitude = 2^22
    // ---------------------------------------------------------------
    real pi_val = 3.14159265358979;
    integer sample_num = 0;
    reg [23:0] current_sample = 24'd0;
    reg [4:0]  mic_bit_cnt = 5'd0;
    reg [23:0] mic_shift = 24'd0;
    reg        mic_ws_prev = 1'b0;

    // Generate sine sample value
    real angle;
    real sine_val;

    // On falling SCK, drive SD (simulating INMP441 behavior)
    always @(negedge i2s_sck or posedge btn_reset) begin
        if (btn_reset) begin
            mic_bit_cnt <= 5'd0;
            mic_ws_prev <= 1'b0;
            mic_shift   <= 24'd0;
            i2s_sd      <= 1'b0;
            sample_num  <= 0;
        end else begin
            // Detect WS transition → new frame
            if (i2s_ws != mic_ws_prev) begin
                mic_ws_prev <= i2s_ws;
                mic_bit_cnt <= 5'd0;

                if (i2s_ws == 1'b0) begin
                    // Left channel: load new sine sample
                    angle = 2.0 * pi_val * 1000.0 * sample_num / 46875.0;
                    sine_val = $sin(angle);
                    current_sample = $rtoi(sine_val * 4194304.0);
                    mic_shift <= current_sample;
                    sample_num <= sample_num + 1;
                end else begin
                    // Right channel: zeros
                    mic_shift <= 24'd0;
                end
            end

            // Shift out MSB-first
            if (mic_bit_cnt < 5'd24) begin
                i2s_sd      <= mic_shift[23];
                mic_shift   <= {mic_shift[22:0], 1'b0};
                mic_bit_cnt <= mic_bit_cnt + 5'd1;
            end else begin
                i2s_sd      <= 1'b0;
                mic_bit_cnt <= mic_bit_cnt + 5'd1;
            end
        end
    end

    // ---------------------------------------------------------------
    // UART receiver model — captures bytes from uart_tx
    // 115200 baud, 8N1
    // ---------------------------------------------------------------
    localparam CLKS_PER_BIT = 104;

    reg [7:0]  uart_rx_byte = 8'd0;
    reg        uart_rx_valid = 1'b0;
    integer    uart_byte_count = 0;

    // Packet decoder
    reg [7:0] pkt_buffer [0:31];
    integer   pkt_idx = 0;
    reg       in_packet = 1'b0;
    reg [7:0] prev_byte = 8'd0;

    task uart_receive_byte;
        integer i;
        begin
            // Wait for start bit (falling edge on uart_tx)
            @(negedge uart_tx);
            // Move to middle of start bit
            #(CLKS_PER_BIT * 83.33 / 2);
            // Verify still low (valid start bit)
            if (uart_tx == 1'b0) begin
                // Sample 8 data bits
                for (i = 0; i < 8; i = i + 1) begin
                    #(CLKS_PER_BIT * 83.33);
                    uart_rx_byte[i] = uart_tx;
                end
                // Skip stop bit
                #(CLKS_PER_BIT * 83.33);
                uart_rx_valid = 1'b1;
                uart_byte_count = uart_byte_count + 1;
            end
        end
    endtask

    // Continuous UART receiver
    initial begin
        forever begin
            uart_rx_valid = 1'b0;
            if (uart_tx == 1'b1) begin
                uart_receive_byte;
                if (uart_rx_valid) begin
                    // Packet detection: look for 0xAA 0x55 sync marker
                    if (prev_byte == 8'hAA && uart_rx_byte == 8'h55) begin
                        in_packet = 1'b1;
                        pkt_idx = 0;
                        pkt_buffer[0] = 8'hAA;
                        pkt_buffer[1] = 8'h55;
                        pkt_idx = 2;
                    end else if (in_packet) begin
                        pkt_buffer[pkt_idx] = uart_rx_byte;
                        pkt_idx = pkt_idx + 1;
                        if (pkt_idx >= 27) begin
                            // Complete packet received — decode and display
                            $display("\n[%0t] === UART Packet Received ===", $time);
                            $display("  Frame:    %0d", {pkt_buffer[2], pkt_buffer[3]});
                            $display("  Peak Bin: %0d", {pkt_buffer[4], pkt_buffer[5]});
                            $display("  Peak Mag: %0d", {pkt_buffer[6], pkt_buffer[7]});
                            $display("  Band 0 (sub-bass):   %0d", {pkt_buffer[8],  pkt_buffer[9]});
                            $display("  Band 1 (bass):       %0d", {pkt_buffer[10], pkt_buffer[11]});
                            $display("  Band 2 (low-mid):    %0d", {pkt_buffer[12], pkt_buffer[13]});
                            $display("  Band 3 (mid):        %0d", {pkt_buffer[14], pkt_buffer[15]});
                            $display("  Band 4 (high-mid):   %0d", {pkt_buffer[16], pkt_buffer[17]});
                            $display("  Band 5 (presence):   %0d", {pkt_buffer[18], pkt_buffer[19]});
                            $display("  Band 6 (brilliance): %0d", {pkt_buffer[20], pkt_buffer[21]});
                            $display("  Band 7 (air):        %0d", {pkt_buffer[22], pkt_buffer[23]});
                            $display("  Centroid: %0d", {pkt_buffer[24], pkt_buffer[25]});
                            $display("  Checksum: 0x%02X", pkt_buffer[26]);

                            // Verify: for 1 kHz tone, peak bin should be near 11
                            if ({pkt_buffer[4], pkt_buffer[5]} >= 16'd9 &&
                                {pkt_buffer[4], pkt_buffer[5]} <= 16'd13)
                                $display("  PEAK BIN CHECK: PASS (expected ~11)");
                            else
                                $display("  PEAK BIN CHECK: FAIL (expected ~11, got %0d)",
                                         {pkt_buffer[4], pkt_buffer[5]});

                            in_packet = 1'b0;
                        end
                    end
                    prev_byte = uart_rx_byte;
                end
            end else begin
                @(posedge clk);
            end
        end
    end

    // ---------------------------------------------------------------
    // Test sequence
    // ---------------------------------------------------------------
    initial begin
        $dumpfile("acoustic_top_tb.vcd");
        $dumpvars(0, acoustic_top_tb);

        $display("=== Acoustic Fingerprint Device — System Testbench ===");
        $display("Generating 1 kHz tone, Fs=46875 Hz, 512-pt FFT");
        $display("Expected peak bin: ~11 (1000 Hz / 91.6 Hz per bin)\n");

        // Reset
        btn_reset = 1'b1;
        btn_start = 1'b0;
        #1_000_000;   // 1 ms reset

        btn_reset = 1'b0;
        $display("[%0t] Reset released", $time);

        // Wait for POR to complete (~10 ms)
        #11_000_000;

        // Start capture
        btn_start = 1'b1;
        #1_000_000;
        btn_start = 1'b0;
        $display("[%0t] Capture started (btn_start pressed)", $time);

        // Wait for multiple FFT frames to complete and packets to transmit
        // Frame period ≈ 10.9 ms, need 512 samples + processing + UART
        // Wait for ~100 ms to capture several complete frames
        #100_000_000;

        $display("\n=== Test Complete ===");
        $display("Total UART bytes received: %0d", uart_byte_count);
        $finish;
    end

    // Timeout watchdog: 200 ms
    initial begin
        #200_000_000;
        $display("TIMEOUT: Simulation exceeded 200 ms");
        $display("UART bytes received: %0d", uart_byte_count);
        $finish;
    end

endmodule
