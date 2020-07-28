`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:     SHU
// Engineer:    lf
// 
// Create Date: 2020/04/26 16:24:02
// Design Name: 
// Module Name: csa_adder_3i_32b
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//              32 位 3 输入 CSA 加法器，不考虑进位 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module csa_adder_3i_32b(
    input   [31:0]      A,
    input   [31:0]      B,
    input   [31:0]      C,
    output  [31:0]      R   
    );

    wire [31:0]     S;
    wire [31:0]     Ca;
    wire [33:0]     R_tmp;

    //3-2 CSA
    assign  S = A ^ B ^ C;
    assign  Ca = (A & B) | (A & C) | (B & C);
    
    //加法器
    assign  R_tmp = {Ca,{1'b0}} + S;

    //输出端口,取低位，不考虑进位
    assign  R = R_tmp[31:0];
endmodule
