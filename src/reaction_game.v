`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: reaction_game
// Description: Reaction time game with random LED patterns
//              User must flip switches matching lit LEDs as fast as possible
//              Displays elapsed time in milliseconds on 7-segment display
//////////////////////////////////////////////////////////////////////////////////

module reaction_game(
    input wire clk,              // 12MHz clock
    input wire key0,             // Start button (key[0])
    input wire [9:0] sw,         // 10 switches
    output reg [9:0] led,        // 10 LEDs
    output reg [7:0] seg,        // 7-segment segments
    output reg [5:0] hex         // Digit select
);

    // State machine states
    localparam IDLE = 3'd0;
    localparam COUNTDOWN = 3'd1;
    localparam WAIT_RANDOM = 3'd2;
    localparam GAME_ACTIVE = 3'd3;
    localparam SHOW_RESULT = 3'd4;
    
    reg [2:0] state = IDLE;
    
    // Button debouncing for key0
    reg [19:0] key0_debounce = 0;
    reg key0_sync = 1;
    reg key0_pressed = 0;
    
    always @(posedge clk) begin
        if (key0 == 0) begin  // Assuming active-low button
            if (key0_debounce < 20'd240000) // 20ms debounce at 12MHz
                key0_debounce <= key0_debounce + 1;
            else
                key0_sync <= 0;
        end else begin
            key0_debounce <= 0;
            key0_sync <= 1;
        end
    end
    
    reg key0_prev = 1;
    always @(posedge clk) begin
        key0_prev <= key0_sync;
        key0_pressed <= (key0_prev == 1) && (key0_sync == 0); // Falling edge
    end
    
    // Random number generator (16-bit LFSR)
    reg [15:0] lfsr = 16'hACE1;
    wire feedback = lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10];
    
    always @(posedge clk) begin
        lfsr <= {lfsr[14:0], feedback};
    end
    
    // LED pattern generation (1-4 random LEDs)
    reg [9:0] target_pattern = 0;
    reg [1:0] num_leds = 0; // 0=1 LED, 1=2 LEDs, 2=3 LEDs, 3=4 LEDs
    
    // Countdown timer (3 seconds before game starts)
    reg [25:0] countdown_counter = 0;
    reg [3:0] countdown_value = 3;
    localparam COUNT_1SEC = 26'd12_000_000; // 1 second at 12MHz
    
    // Game timer (measures reaction time in centiseconds, 10ms units)
    reg [31:0] game_timer = 0;
    reg [15:0] elapsed_cs = 0;  // Elapsed centiseconds (hundredths)
    localparam COUNT_10MS = 16'd120_000; // 10ms at 12MHz
    reg [16:0] cs_counter = 0;
    
    // Time components for MM.SS.CC format
    reg [5:0] minutes = 0;    // 0-59
    reg [5:0] seconds = 0;    // 0-59
    reg [6:0] centisec = 0;   // 0-99
    
    // BCD digits for display (6 digits for MM.SS.CC)
    wire [3:0] digit0, digit1, digit2, digit3, digit4, digit5;
    reg [23:0] display_value = 0;  // Expanded to 24 bits for 6 digits
    
    // Display multiplexing (now 6 digits)
    reg [10:0] refresh_counter = 0;
    wire [2:0] digit_select = refresh_counter[10:8];  // 3 bits for 6 digits
    reg [3:0] current_digit;
    
    always @(posedge clk) begin
        refresh_counter <= refresh_counter + 1;
    end
    
    // Select current digit
    always @(*) begin
        case (digit_select)
            3'd0: current_digit = digit0;  // Centiseconds ones
            3'd1: current_digit = digit1;  // Centiseconds tens
            3'd2: current_digit = digit2;  // Seconds ones
            3'd3: current_digit = digit3;  // Seconds tens
            3'd4: current_digit = digit4;  // Minutes ones
            3'd5: current_digit = digit5;  // Minutes tens
            default: current_digit = 4'd0;
        endcase
    end
    
    // 7-segment decoder (active-high segments)
    reg [7:0] seg_pattern;
    always @(*) begin
        case (current_digit)
            4'd0: seg_pattern = 8'b00111111;
            4'd1: seg_pattern = 8'b00000110;
            4'd2: seg_pattern = 8'b01011011;
            4'd3: seg_pattern = 8'b01001111;
            4'd4: seg_pattern = 8'b01100110;
            4'd5: seg_pattern = 8'b01101101;
            4'd6: seg_pattern = 8'b01111101;
            4'd7: seg_pattern = 8'b00000111;
            4'd8: seg_pattern = 8'b01111111;
            4'd9: seg_pattern = 8'b01101111;
            default: seg_pattern = 8'b00000000;
        endcase
    end
    
    // Digit select (active-low) - now 6 digits
    always @(*) begin
        case (digit_select)
            3'd0: hex = 6'b111110;  // Digit 0 (rightmost - centiseconds ones)
            3'd1: hex = 6'b111101;  // Digit 1 (centiseconds tens)
            3'd2: hex = 6'b111011;  // Digit 2 (seconds ones)
            3'd3: hex = 6'b110111;  // Digit 3 (seconds tens)
            3'd4: hex = 6'b101111;  // Digit 4 (minutes ones)
            3'd5: hex = 6'b011111;  // Digit 5 (minutes tens)
            default: hex = 6'b111111;
        endcase
    end
    
    always @(posedge clk) begin
        seg <= seg_pattern;
    end
    
    // Convert elapsed centiseconds to minutes, seconds, centiseconds
    always @(*) begin
        centisec = elapsed_cs % 100;
        seconds = (elapsed_cs / 100) % 60;
        minutes = (elapsed_cs / 6000) % 60;
    end
    
    // Binary to BCD conversion for 6-digit display (MMSSCC format)
    wire [3:0] cs_ones, cs_tens;
    wire [3:0] sec_ones, sec_tens;
    wire [3:0] min_ones, min_tens;
    
    // Convert centiseconds (0-99)
    assign cs_ones = centisec % 10;
    assign cs_tens = centisec / 10;
    
    // Convert seconds (0-59)
    assign sec_ones = seconds % 10;
    assign sec_tens = seconds / 10;
    
    // Convert minutes (0-59)
    assign min_ones = minutes % 10;
    assign min_tens = minutes / 10;
    
    // Assign to digit outputs (show countdown in COUNTDOWN state, time otherwise)
    assign digit0 = (state == COUNTDOWN) ? display_value[3:0] : cs_ones;
    assign digit1 = (state == COUNTDOWN) ? display_value[7:4] : cs_tens;
    assign digit2 = (state == COUNTDOWN) ? display_value[11:8] : sec_ones;
    assign digit3 = (state == COUNTDOWN) ? display_value[15:12] : sec_tens;
    assign digit4 = (state == COUNTDOWN) ? display_value[19:16] : min_ones;
    assign digit5 = (state == COUNTDOWN) ? display_value[23:20] : min_tens;
    
    // Main state machine
    always @(posedge clk) begin
        case (state)
            IDLE: begin
                led <= 10'd0;
                display_value <= 24'd0;
                elapsed_cs <= 16'd0;
                countdown_value <= 4'd3;
                countdown_counter <= 0;
                
                if (key0_pressed) begin
                    state <= COUNTDOWN;
                    countdown_counter <= 0;
                end
            end
            
            COUNTDOWN: begin
                // Countdown 3, 2, 1...
                if (countdown_counter >= COUNT_1SEC - 1) begin
                    countdown_counter <= 0;
                    if (countdown_value > 0) begin
                        countdown_value <= countdown_value - 1;
                    end else begin
                        state <= WAIT_RANDOM;
                        countdown_counter <= 0;  // Reset for random delay
                    end
                end else begin
                    countdown_counter <= countdown_counter + 1;
                end
                display_value <= {20'd0, countdown_value};
                led <= 10'd0;
            end
            
            WAIT_RANDOM: begin
                // Wait random time (0.5 to 2 seconds) then light LEDs
                // Use lfsr to generate delay between 6M and 24M cycles (0.5-2s)
                if (countdown_counter >= (26'd6_000_000 + {lfsr[3:0], 21'd0})) begin
                    // Generate random LED pattern using different LFSR bits
                    num_leds <= lfsr[15:14]; // Use high bits for count
                    
                    // Create random scattered LED patterns (not consecutive)
                    // Use different LFSR bit ranges to select individual LED positions
                    case (lfsr[15:14])  // Use high bits for number of LEDs
                        2'b00: begin // 1 LED - pick 1 random position
                            case (lfsr[13:10])  // 16 values, map to 10 LEDs
                                4'd0, 4'd10: target_pattern <= 10'b0000000001;  // LED 0
                                4'd1, 4'd11: target_pattern <= 10'b0000000010;  // LED 1
                                4'd2, 4'd12: target_pattern <= 10'b0000000100;  // LED 2
                                4'd3, 4'd13: target_pattern <= 10'b0000001000;  // LED 3
                                4'd4, 4'd14: target_pattern <= 10'b0000010000;  // LED 4
                                4'd5, 4'd15: target_pattern <= 10'b0000100000;  // LED 5
                                4'd6: target_pattern <= 10'b0001000000;  // LED 6
                                4'd7: target_pattern <= 10'b0010000000;  // LED 7
                                4'd8: target_pattern <= 10'b0100000000;  // LED 8
                                4'd9: target_pattern <= 10'b1000000000;  // LED 9
                            endcase
                        end
                        2'b01: begin // 2 LEDs - pick 2 random scattered positions
                            case (lfsr[12:9])  // 16 patterns for 2 LEDs
                                4'd0: target_pattern <= 10'b0000001001;  // LED 0,3
                                4'd1: target_pattern <= 10'b0000010010;  // LED 1,4
                                4'd2: target_pattern <= 10'b0000100100;  // LED 2,5
                                4'd3: target_pattern <= 10'b0001001000;  // LED 3,6
                                4'd4: target_pattern <= 10'b0010010000;  // LED 4,7
                                4'd5: target_pattern <= 10'b0100100000;  // LED 5,8
                                4'd6: target_pattern <= 10'b1001000000;  // LED 6,9
                                4'd7: target_pattern <= 10'b0001000010;  // LED 1,6
                                4'd8: target_pattern <= 10'b0010000100;  // LED 2,7
                                4'd9: target_pattern <= 10'b0100001000;  // LED 3,8
                                4'd10: target_pattern <= 10'b1000010000;  // LED 4,9
                                4'd11: target_pattern <= 10'b0000100001;  // LED 0,5
                                4'd12: target_pattern <= 10'b1000000100;  // LED 2,9
                                4'd13: target_pattern <= 10'b0100000001;  // LED 0,8
                                4'd14: target_pattern <= 10'b0010000001;  // LED 0,7
                                4'd15: target_pattern <= 10'b0001000001;  // LED 0,6
                            endcase
                        end
                        2'b10: begin // 3 LEDs - pick 3 random scattered positions
                            case (lfsr[11:8])  // 16 patterns for 3 LEDs
                                4'd0: target_pattern <= 10'b0001001001;  // LED 0,3,6
                                4'd1: target_pattern <= 10'b0010010010;  // LED 1,4,7
                                4'd2: target_pattern <= 10'b0100100100;  // LED 2,5,8
                                4'd3: target_pattern <= 10'b1001001000;  // LED 3,6,9
                                4'd4: target_pattern <= 10'b0001010001;  // LED 0,4,6
                                4'd5: target_pattern <= 10'b0010100010;  // LED 1,5,7
                                4'd6: target_pattern <= 10'b0101000100;  // LED 2,6,8
                                4'd7: target_pattern <= 10'b1010001000;  // LED 3,7,9
                                4'd8: target_pattern <= 10'b0100010001;  // LED 0,4,8
                                4'd9: target_pattern <= 10'b1000100010;  // LED 1,5,9
                                4'd10: target_pattern <= 10'b0001000101;  // LED 0,2,6
                                4'd11: target_pattern <= 10'b0010001010;  // LED 1,3,7
                                4'd12: target_pattern <= 10'b0100010100;  // LED 2,4,8
                                4'd13: target_pattern <= 10'b1000101000;  // LED 3,5,9
                                4'd14: target_pattern <= 10'b1001000001;  // LED 0,6,9
                                4'd15: target_pattern <= 10'b0100100001;  // LED 0,5,8
                            endcase
                        end
                        2'b11: begin // 4 LEDs - pick 4 random scattered positions
                            case (lfsr[10:7])  // 16 patterns for 4 LEDs
                                4'd0: target_pattern <= 10'b0001010101;  // LED 0,2,4,6
                                4'd1: target_pattern <= 10'b0010101010;  // LED 1,3,5,7
                                4'd2: target_pattern <= 10'b0101010100;  // LED 2,4,6,8
                                4'd3: target_pattern <= 10'b1010101000;  // LED 3,5,7,9
                                4'd4: target_pattern <= 10'b1001001001;  // LED 0,3,6,9
                                4'd5: target_pattern <= 10'b0110011001;  // LED 0,3,4,5
                                4'd6: target_pattern <= 10'b1001100110;  // LED 1,2,5,6,9
                                4'd7: target_pattern <= 10'b0100110011;  // LED 0,1,4,5,8
                                4'd8: target_pattern <= 10'b1000100101;  // LED 0,2,5,9
                                4'd9: target_pattern <= 10'b0100101010;  // LED 1,3,5,8
                                4'd10: target_pattern <= 10'b1010010010;  // LED 1,4,7,9
                                4'd11: target_pattern <= 10'b0101001001;  // LED 0,3,6,8
                                4'd12: target_pattern <= 10'b1010100100;  // LED 2,5,7,9
                                4'd13: target_pattern <= 10'b0101010001;  // LED 0,4,6,8
                                4'd14: target_pattern <= 10'b1000110010;  // LED 1,4,5,9
                                4'd15: target_pattern <= 10'b0011001100;  // LED 2,3,6,7
                            endcase
                        end
                    endcase
                    
                    state <= GAME_ACTIVE;
                    cs_counter <= 0;
                    elapsed_cs <= 0;
                end else begin
                    countdown_counter <= countdown_counter + 1;
                end
                display_value <= 24'd0;
                led <= 10'd0;
            end
            
            GAME_ACTIVE: begin
                led <= target_pattern;
                
                // Increment timer (count centiseconds, 10ms units)
                if (cs_counter >= COUNT_10MS - 1) begin
                    cs_counter <= 0;
                    if (elapsed_cs < 16'd35999)  // Max 59:59.99
                        elapsed_cs <= elapsed_cs + 1;
                end else begin
                    cs_counter <= cs_counter + 1;
                end
                
                // Check if switches match target
                if (sw == target_pattern) begin
                    state <= SHOW_RESULT;
                end
            end
            
            SHOW_RESULT: begin
                led <= target_pattern; // Keep LEDs lit
                // Display shows final time in MM.SS.CC format
                
                // Wait for all switches to be OFF to reset
                if (sw == 10'd0) begin
                    state <= IDLE;
                end
            end
            
            default: state <= IDLE;
        endcase
    end

endmodule
