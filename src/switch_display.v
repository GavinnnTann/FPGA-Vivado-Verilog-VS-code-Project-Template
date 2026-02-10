`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: switch_display
// Description: Display 10-bit switch value (0-1023) on 7-segment displays
//              Uses 4 digits to show decimal value
//              CMOD A7 has 12MHz clock
//////////////////////////////////////////////////////////////////////////////////

module switch_display(
    input wire clk,              // 12MHz clock input
    input wire [9:0] sw,         // 10 switches
    output reg [7:0] seg,        // 7-segment segments (active-low)
    output reg [5:0] hex         // Digit select (active-low), only use [3:0]
);

    // Convert 10-bit binary to 4-digit decimal (BCD)
    wire [3:0] digit0, digit1, digit2, digit3;  // ones, tens, hundreds, thousands
    
    // Instantiate binary to BCD converter
    binary_to_bcd u_bin2bcd (
        .binary(sw),
        .thousands(digit3),
        .hundreds(digit2),
        .tens(digit1),
        .ones(digit0)
    );
    
    // Multiplexing counter - refresh rate divider
    // 12MHz / 1024 = ~11.7kHz refresh rate per digit
    // 4 digits = ~2.9kHz per digit (flicker-free)
    reg [9:0] refresh_counter;
    wire [1:0] digit_select;
    
    always @(posedge clk) begin
        refresh_counter <= refresh_counter + 1;
    end
    
    assign digit_select = refresh_counter[9:8];  // 2-bit counter for 4 digits
    
    // Current digit to display
    reg [3:0] current_digit;
    
    // Select which digit to display
    always @(*) begin
        case (digit_select)
            2'b00: current_digit = digit0;  // Ones
            2'b01: current_digit = digit1;  // Tens
            2'b10: current_digit = digit2;  // Hundreds
            2'b11: current_digit = digit3;  // Thousands
            default: current_digit = 4'd0;
        endcase
    end
    
    // 7-segment decoder (active-high segments - common cathode)
    // Segment mapping: {DP, G, F, E, D, C, B, A}
    reg [7:0] seg_pattern;
    
    always @(*) begin
        case (current_digit)
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
            default: seg_pattern = 8'b00000000;  // Blank
        endcase
    end
    
    // Digit enable (active-LOW) - 0=enable, 1=disable
    // Only ONE digit should be enabled (LOW) at a time for proper multiplexing
    always @(*) begin
        case (digit_select)
            2'b00: hex = 6'b111110;  // Enable digit 0 only (rightmost)
            2'b01: hex = 6'b111101;  // Enable digit 1 only
            2'b10: hex = 6'b111011;  // Enable digit 2 only
            2'b11: hex = 6'b110111;  // Enable digit 3 only (leftmost)
            default: hex = 6'b111111;  // All off
        endcase
    end
    
    // Output segments (register to sync with digit select)
    always @(posedge clk) begin
        seg <= seg_pattern;
    end

endmodule

//////////////////////////////////////////////////////////////////////////////////
// Binary to BCD Converter using Double Dabble Algorithm
// Converts 10-bit binary (0-1023) to 4-digit BCD
//////////////////////////////////////////////////////////////////////////////////
module binary_to_bcd(
    input wire [9:0] binary,
    output reg [3:0] thousands,
    output reg [3:0] hundreds,
    output reg [3:0] tens,
    output reg [3:0] ones
);

    integer i;
    reg [25:0] shift_reg;  // 10 bits binary + 16 bits BCD (4 digits x 4 bits)
    
    always @(*) begin
        shift_reg = {16'd0, binary};
        
        // Double dabble algorithm
        for (i = 0; i < 10; i = i + 1) begin
            // Add 3 to any BCD digit > 4
            if (shift_reg[13:10] > 4) shift_reg[13:10] = shift_reg[13:10] + 3;
            if (shift_reg[17:14] > 4) shift_reg[17:14] = shift_reg[17:14] + 3;
            if (shift_reg[21:18] > 4) shift_reg[21:18] = shift_reg[21:18] + 3;
            if (shift_reg[25:22] > 4) shift_reg[25:22] = shift_reg[25:22] + 3;
            
            // Shift left
            shift_reg = shift_reg << 1;
        end
        
        // Extract BCD digits
        ones = shift_reg[13:10];
        tens = shift_reg[17:14];
        hundreds = shift_reg[21:18];
        thousands = shift_reg[25:22];
    end

endmodule
