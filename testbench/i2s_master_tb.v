`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench: i2s_master_tb
// Description: Simulates INMP441 microphone behavior to validate I2S master.
//              Generates SCK/WS-responsive SD output with known 24-bit test
//              words and verifies captured samples match expected values.
//////////////////////////////////////////////////////////////////////////////////

module i2s_master_tb;

    // ---------------------------------------------------------------
    // Clock generation: 12 MHz → period = 83.33 ns
    // ---------------------------------------------------------------
    reg clk = 1'b0;
    always #41.667 clk = ~clk;

    // ---------------------------------------------------------------
    // DUT signals
    // ---------------------------------------------------------------
    reg        rst = 1'b1;
    wire       i2s_sck;
    wire       i2s_ws;
    reg        i2s_sd = 1'b0;
    wire [23:0] sample_data;
    wire        sample_valid;

    // ---------------------------------------------------------------
    // DUT instantiation
    // ---------------------------------------------------------------
    i2s_master uut (
        .clk(clk),
        .rst(rst),
        .i2s_sck(i2s_sck),
        .i2s_ws(i2s_ws),
        .i2s_sd(i2s_sd),
        .sample_data(sample_data),
        .sample_valid(sample_valid)
    );

    // ---------------------------------------------------------------
    // Simulated INMP441 model
    // Responds to SCK/WS by shifting out 24-bit test words on SD
    // Left channel (WS=0): sends test_word_left MSB-first
    // Right channel (WS=1): sends test_word_right MSB-first
    // Remaining 8 bits in 32-bit frame are tri-state (we drive 0)
    // ---------------------------------------------------------------
    reg [23:0] test_word_left  = 24'h3A5C7E;   // known test pattern
    reg [23:0] test_word_right = 24'h000000;    // right channel (ignored by DUT)
    reg [4:0]  sd_bit_cnt = 5'd0;
    reg        ws_prev_model = 1'b0;
    reg [23:0] sd_shift_out = 24'd0;

    // Drive SD on falling edge of SCK (INMP441 spec: data transitions on falling SCK)
    always @(negedge i2s_sck or posedge rst) begin
        if (rst) begin
            sd_bit_cnt    <= 5'd0;
            ws_prev_model <= 1'b0;
            sd_shift_out  <= 24'd0;
            i2s_sd        <= 1'b0;
        end else begin
            // Detect WS edge
            if (i2s_ws != ws_prev_model) begin
                ws_prev_model <= i2s_ws;
                sd_bit_cnt    <= 5'd0;
                // Load the appropriate channel data
                // I2S spec: data for new channel starts one SCK after WS edge
                if (i2s_ws == 1'b0)
                    sd_shift_out <= test_word_left;
                else
                    sd_shift_out <= test_word_right;
            end

            // Output MSB of shift register
            if (sd_bit_cnt < 5'd24) begin
                i2s_sd       <= sd_shift_out[23];
                sd_shift_out <= {sd_shift_out[22:0], 1'b0};
                sd_bit_cnt   <= sd_bit_cnt + 5'd1;
            end else begin
                i2s_sd <= 1'b0;  // tri-state / zero for remaining bits
                sd_bit_cnt <= sd_bit_cnt + 5'd1;
            end
        end
    end

    // ---------------------------------------------------------------
    // Sample capture verification
    // ---------------------------------------------------------------
    integer sample_count = 0;
    integer errors = 0;

    always @(posedge clk) begin
        if (sample_valid) begin
            sample_count = sample_count + 1;
            $display("[%0t] Sample %0d: 0x%06X", $time, sample_count, sample_data);

            // After a few startup frames, verify left-channel data matches
            if (sample_count > 2) begin
                if (sample_data != test_word_left) begin
                    $display("  ERROR: Expected 0x%06X, got 0x%06X", test_word_left, sample_data);
                    errors = errors + 1;
                end else begin
                    $display("  OK: Matches expected value");
                end
            end
        end
    end

    // ---------------------------------------------------------------
    // Test sequence
    // ---------------------------------------------------------------
    initial begin
        $dumpfile("i2s_master_tb.vcd");
        $dumpvars(0, i2s_master_tb);

        $display("=== I2S Master Testbench ===");
        $display("Test word (left channel): 0x%06X", test_word_left);

        // Hold reset
        rst = 1'b1;
        #500;
        rst = 1'b0;
        $display("[%0t] Reset released", $time);

        // Wait for several complete I2S frames
        // Frame period = 64 SCK cycles × 333.3 ns ≈ 21.3 µs
        // Wait for ~10 frames ≈ 213 µs
        #250_000;

        // Change test word mid-stream
        test_word_left = 24'h7FFFFF;  // max positive value
        $display("\n[%0t] Changed test word to 0x7FFFFF", $time);
        #200_000;

        // Test with negative value
        test_word_left = 24'h800001;  // large negative value
        $display("\n[%0t] Changed test word to 0x800001", $time);
        #200_000;

        // Test with zero
        test_word_left = 24'h000000;
        $display("\n[%0t] Changed test word to 0x000000", $time);
        #100_000;

        // Summary
        $display("\n=== Test Complete ===");
        $display("Total samples captured: %0d", sample_count);
        $display("Errors: %0d", errors);
        if (errors == 0)
            $display("RESULT: PASS");
        else
            $display("RESULT: FAIL");

        $finish;
    end

    // Timeout watchdog
    initial begin
        #2_000_000;
        $display("TIMEOUT: Simulation exceeded 2 ms");
        $finish;
    end

endmodule
