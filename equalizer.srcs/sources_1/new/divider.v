`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/15 13:58:37
// Design Name: 
// Module Name: divider
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

module divider (
    input clock,
    input reset,
    input enable,

    input signed [31:0] dividend,
    input signed [23:0] divisor,
    input input_strobe,

    output signed [31:0] quotient,
    output output_strobe
);

div_gen div_inst (
    .clk(clock),
    .dividend(dividend),
    .divisor(divisor),
    .input_strobe(input_strobe),
    .output_strobe(output_strobe),
    .quotient(quotient)
);

// // --------old one---------------
// div_gen_v3_0 div_inst (
//     .clk(clock),
//     .dividend(dividend),
//     .divisor(divisor),
//     .quotient(quotient)
// );

// delayT #(.DATA_WIDTH(1), .DELAY(36)) out_inst (
//     .clock(clock),
//     .reset(reset),
//     .data_in(input_strobe),
//     .data_out(output_strobe)
// );

endmodule

