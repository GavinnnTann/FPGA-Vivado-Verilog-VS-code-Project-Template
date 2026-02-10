`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: blink
// Description: Simple LED blink example for CMOD A7
//              Blinks the onboard LED at approximately 1Hz
//              CMOD A7 has 12MHz clock
//////////////////////////////////////////////////////////////////////////////////

module blink(
    input wire clk,           // 12MHz clock input
    output reg led = 1'b0     // LED output (active-high: 1=ON, 0=OFF)
);

    // Counter to divide clock
    // For 12MHz clock, count to 6,000,000 for 0.5 second (1Hz blink rate)
    localparam COUNTER_MAX = 6_000_000;
    reg [22:0] counter = 23'd0;
    
    always @(posedge clk) begin
        if (counter >= COUNTER_MAX - 1) begin
            counter <= 23'd0;
            led <= ~led;      // Toggle LED
        end else begin
            counter <= counter + 1;
        end
    end

endmodule
