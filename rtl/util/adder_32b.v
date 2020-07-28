`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:     SHU
// Engineer:    lf
// 
// Create Date: 2020/04/26 16:24:02
// Design Name: 
// Module Name: adder_32b
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//              32 位 加法器 性能分析用
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module adder_32b(
    input   [31:0]      A,
    input   [31:0]      B,
    output  [31:0]      R   
    );
    wire    [32:0]      R_tmp;         
    assign      R_tmp   = A + B;
    assign      R       = R_tmp[31:0];
endmodule
