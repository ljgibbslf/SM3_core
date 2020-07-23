`timescale 1ns / 1ps
// `include "../rtl/inc/sm3_cfg"
`include "sm3_cfg.v"
//////////////////////////////////////////////////////////////////////////////////
// Author:        ljgibbs / lf_gibbs@163.com
// Create Date: 2020/07/21 
// Design Name: sm3
// Module Name: tb_sm3_pad_top
// Description:
//      SM3 填充模块 testbench
//          测试 sm3_pad_core 
// Dependencies: 
//      inc/sm3_cfg.v
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////
module tb_sm3_pad_top (                 
);

//logic
// logic                       clk;
// logic                       rst_n;

// logic [`INPT_DW1:0]         msg_inpt_d_i;
// logic [`INPT_BYTE_DW1:0]    msg_inpt_vld_byte_i;
// logic                       msg_inpt_vld_i;
// logic                       msg_inpt_lst_i;

// logic                       pad_otpt_ena_i;

// logic                       msg_inpt_rdy_o;
// logic                       pad_otpt_d_o;
// logic                       pad_otpt_lst_o;
// logic                       pad_otpt_vld_o;

`ifdef SM3_INPT_DW_32
    localparam [1:0]            INPT_WORD_NUM               =   2'd1;
`elsif SM3_INPT_DW_64
    localparam [1:0]            INPT_WORD_NUM               =   2'd2;
`endif

//interface
sm3_if sm3if();

//uut
// sm3_pad_core U_sm3_pad_core(
//     .clk                    (clk                    ),
//     .rst_n                  (rst_n                  ),

//     .msg_inpt_d_i           (msg_inpt_d_i           ),
//     .msg_inpt_vld_byte_i    (msg_inpt_vld_byte_i    ),
//     .msg_inpt_vld_i         (msg_inpt_vld_i         ),
//     .msg_inpt_lst_i         (msg_inpt_lst_i         ),

//     .pad_otpt_ena_i         (pad_otpt_ena_i         ),

//     .msg_inpt_rdy_o         (msg_inpt_rdy_o         ),

//     .pad_otpt_d_o           (pad_otpt_d_o           ),
//     .pad_otpt_lst_o         (pad_otpt_lst_o         ),
//     .pad_otpt_vld_o         (pad_otpt_vld_o         )
// );

//uut with bus wrapper
sm3_pad_core_wrapper U_sm3_pad_core_wrapper(
    sm3if
);

initial begin
    sm3if.clk                     =0;
    sm3if.rst_n                   =0;
    sm3if.msg_inpt_d_i            =1;
    sm3if.msg_inpt_vld_byte_i     =0;
    sm3if.msg_inpt_vld_i          =0;
    sm3if.msg_inpt_lst_i          =0;
    sm3if.pad_otpt_ena_i          =1;

    #100;
    sm3if.rst_n                   =1;

    @(posedge sm3if.clk);
    task_pad_inpt(61'd10);

end

always #5 sm3if.clk = ~sm3if.clk; 

//激励任务
task automatic task_pad_inpt(input logic [60:0] byte_num);
    repeat(byte_num)begin
        sm3if.msg_inpt_vld_i = 1'b1;
        @(posedge sm3if.clk);   
    end
    sm3if.msg_inpt_vld_i = 1'b0;
    @(posedge sm3if.clk);   
    
endtask //automatic

endmodule