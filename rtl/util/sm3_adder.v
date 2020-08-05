`timescale 1ns / 1ps
`include "sm3_cfg.v"
//////////////////////////////////////////////////////////////////////////////////
// Company:     SHU
// Engineer:    lf
// 
// Create Date: 2020/04/26 16:24:02
// Design Name: 
// Module Name: sm3_adder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//              SM3 32 位 3 输入 加法器，
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module sm3_adder(
    input   [31:0]      A,
    input   [31:0]      B,
    input   [31:0]      C,
    output  [31:0]      R   
    );

    `ifdef SM3_CMPRSS_CSA_ADD
        //使用CSA加法器
        csa_adder_3i_32b U_csa_adder_3i_32b(
            .A(A),
            .B(B),
            .C(C),
            .R(R)  
        );
    `else
        //使用两级加法器
        wire [31:0]     tmp;
        adder_32b U_adder_0(
            .A(A),
            .B(B),
            .R(tmp) 
        );
        adder_32b U_adder_1(
            .A(tmp),
            .B(C),
            .R(R) 
        );

    `endif
    
endmodule
