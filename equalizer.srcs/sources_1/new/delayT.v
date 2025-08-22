`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/15 14:02:49
// Design Name: 
// Module Name: delayT
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module delayT
#(
    parameter DATA_WIDTH = 32,
    parameter DELAY = 1
)
(
    input clock,
    input reset,

    input [DATA_WIDTH-1:0] data_in,
    output [DATA_WIDTH-1:0] data_out
);

reg [DATA_WIDTH-1:0] ram[DELAY-1:0];
integer i;

assign data_out = ram[DELAY-1];

always @(posedge clock) begin
    if (reset) begin
        for (i = 0; i < DELAY; i = i+1) begin
            ram[i] <= 0;
        end
    end else begin
        ram[0] <= data_in;
        for (i = 1; i < DELAY; i= i+1) begin
            ram[i] <= ram[i-1];
        end
    end
end

endmodule

