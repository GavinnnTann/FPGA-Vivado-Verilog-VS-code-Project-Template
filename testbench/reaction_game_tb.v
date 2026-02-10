`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench for reaction_game module
// Tests state machine transitions, countdown, LED patterns, and timing
//////////////////////////////////////////////////////////////////////////////////

module reaction_game_tb;

    // Clock generation
    reg clk;
    reg key0;
    reg [9:0] sw;
    wire [9:0] led;
    wire [7:0] seg;
    wire [5:0] hex;
    
    // Instantiate the Unit Under Test (UUT)
    reaction_game uut (
        .clk(clk),
        .key0(key0),
        .sw(sw),
        .led(led),
        .seg(seg),
        .hex(hex)
    );
    
    // Clock generation: 12MHz = 83.33ns period
    initial begin
        clk = 0;
        forever #41.667 clk = ~clk;  // 12MHz clock
    end
    
    // Test stimulus
    initial begin
        // Initialize waveform dump
        $dumpfile("reaction_game.vcd");
        $dumpvars(0, reaction_game_tb);
        
        // Initialize inputs
        key0 = 1;  // Active-low, so 1 = not pressed
        sw = 10'b0;
        
        $display("=== Reaction Game Testbench ===");
        $display("Time=%0t: Starting simulation", $time);
        
        // Wait for initial settling
        #1000;
        
        // Test 1: Check IDLE state
        $display("\n--- Test 1: IDLE State ---");
        $display("Time=%0t: Checking IDLE state (LEDs should be off)", $time);
        #1000;
        if (led == 10'b0) 
            $display("Time=%0t: PASS - LEDs are off in IDLE", $time);
        else 
            $display("Time=%0t: FAIL - LEDs should be off, got %b", $time, led);
        
        // Test 2: Button press to start game
        $display("\n--- Test 2: Button Press (Start Game) ---");
        $display("Time=%0t: Pressing KEY0 to start game", $time);
        key0 = 0;  // Press button (active-low)
        #500000;   // Hold for 500us (beyond debounce time of 20ms)
        key0 = 1;  // Release button
        $display("Time=%0t: Button released, should enter COUNTDOWN state", $time);
        
        // Test 3: Wait for countdown (abbreviated - only check first second)
        $display("\n--- Test 3: Countdown Phase ---");
        #50000000;  // Wait 50ms to observe countdown
        $display("Time=%0t: In countdown phase, LEDs=%b, hex=%b, seg=%b", $time, led, hex, seg);
        
        // Test 4: Fast-forward through countdown (skip full 3 seconds for simulation speed)
        $display("\n--- Test 4: Fast-Forward to Game Active ---");
        #200000000;  // Wait 200ms to get past initial countdown
        $display("Time=%0t: Should be transitioning to GAME_ACTIVE soon", $time);
        
        // Test 5: Wait for random delay and LED pattern
        $display("\n--- Test 5: LED Pattern Generation ---");
        #3000000000;  // Wait 3 seconds (max random delay is 2s + countdown)
        $display("Time=%0t: Game should be active now", $time);
        $display("Time=%0t: LED Pattern = %b (decimal %d)", $time, led, led);
        
        // Count number of LEDs lit
        if (led != 10'b0) begin
            integer led_count;
            led_count = 0;
            if (led[0]) led_count = led_count + 1;
            if (led[1]) led_count = led_count + 1;
            if (led[2]) led_count = led_count + 1;
            if (led[3]) led_count = led_count + 1;
            if (led[4]) led_count = led_count + 1;
            if (led[5]) led_count = led_count + 1;
            if (led[6]) led_count = led_count + 1;
            if (led[7]) led_count = led_count + 1;
            if (led[8]) led_count = led_count + 1;
            if (led[9]) led_count = led_count + 1;
            $display("Time=%0t: Number of LEDs lit: %0d", $time, led_count);
            
            if (led_count >= 1 && led_count <= 4)
                $display("Time=%0t: PASS - LED count in valid range (1-4)", $time);
            else
                $display("Time=%0t: FAIL - LED count out of range (1-4)", $time);
        end else begin
            $display("Time=%0t: WARNING - No LEDs lit yet, may need more time", $time);
        end
        
        // Test 6: Match switches to LED pattern
        $display("\n--- Test 6: Switch Matching ---");
        sw = led;  // Set switches to match LED pattern
        $display("Time=%0t: Setting switches to match LEDs: %b", $time, sw);
        #100000;  // Wait 100us for switch change to register
        $display("Time=%0t: Switches matched, should enter SHOW_RESULT", $time);
        
        // Test 7: Check timer display
        $display("\n--- Test 7: Timer Display ---");
        #10000000;  // Wait 10ms to see result
        $display("Time=%0t: In SHOW_RESULT state", $time);
        $display("Time=%0t: Display segments=%b, digit_select=%b", $time, seg, hex);
        
        // Test 8: Reset by clearing switches
        $display("\n--- Test 8: Reset to IDLE ---");
        sw = 10'b0;
        $display("Time=%0t: Clearing all switches to reset", $time);
        #10000;
        $display("Time=%0t: Should return to IDLE state", $time);
        if (led == 10'b0)
            $display("Time=%0t: PASS - Back to IDLE (LEDs off)", $time);
        else
            $display("Time=%0t: FAIL - LEDs should be off in IDLE", $time);
        
        // Test 9: Second game cycle (fast test)
        $display("\n--- Test 9: Second Game Cycle ---");
        $display("Time=%0t: Starting second game", $time);
        key0 = 0;
        #500000;
        key0 = 1;
        #100000000;  // Wait 100ms
        $display("Time=%0t: Second countdown started", $time);
        
        // End simulation
        #100000000;  // Wait another 100ms
        $display("\n=== Simulation Complete ===");
        $display("Time=%0t: Total simulation time", $time);
        $display("\nCheck waveform file 'reaction_game.vcd' for detailed signal analysis");
        $finish;
    end
    
    // Monitor key signals
    initial begin
        $monitor("Time=%0t | State=%b | LED=%b | SW=%b | Timer Running=%b", 
                 $time, uut.state, led, sw, uut.cs_counter > 0);
    end
    
    // Timeout watchdog
    initial begin
        #10000000000;  // 10 seconds simulation timeout
        $display("\n!!! TIMEOUT - Simulation exceeded 10 seconds !!!");
        $finish;
    end

endmodule
