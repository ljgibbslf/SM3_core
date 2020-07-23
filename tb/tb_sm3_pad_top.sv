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
    localparam [31:0]           DATA_INIT_PTTRN             =   32'h01020304;
`elsif SM3_INPT_DW_64
    localparam [1:0]            INPT_WORD_NUM               =   2'd2;
    localparam [63:0]           DATA_INIT_PTTRN             =   64'h0102030401020304;
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
    sm3if.clk                     = 0;
    sm3if.rst_n                   = 0;
    sm3if.msg_inpt_d_i            = DATA_INIT_PTTRN;
    sm3if.msg_inpt_vld_byte_i     = 0;
    sm3if.msg_inpt_vld_i          = 0;
    sm3if.msg_inpt_lst_i          = 0;
    sm3if.pad_otpt_ena_i          = 1;//置高填充模块输出使能

    #100;
    sm3if.rst_n                   =1;

    @(posedge sm3if.clk);
    task_pad_inpt_gntr(61'd10);

end

always #5 sm3if.clk = ~sm3if.clk; 

//产生填充模块输入
task automatic task_pad_inpt_gntr(
    input bit [60:0] byte_num
    );

    //golden pattern
    bit [7:0]   gldn_pttrn[63:0];

    bit [2:0]   unalign_byte_num;
    bit [55:0]  data_inpt_clk_num;

    //生成 golden pattern
    // golden_pttrn_gntr(gldn_pttrn,byte_num);
 
    //根据总线位宽计算数据输入时钟数与非对齐的数据数量
    `ifdef SM3_INPT_DW_32
        unalign_byte_num    =   byte_num[1:0];
        data_inpt_clk_num   =   unalign_byte_num == 0 ? byte_num[60:2] : byte_num[60:2] + 1'b1;
    `elsif SM3_INPT_DW_64
        unalign_byte_num    =   byte_num[2:0];
        data_inpt_clk_num   =   unalign_byte_num == 0 ? byte_num[60:3] : byte_num[60:3] + 1'b1;
    `endif


    //前 N-1 个周期的数据
    repeat(data_inpt_clk_num - 1'b1)begin
        sm3if.msg_inpt_vld_i = 1'b1;
        @(posedge sm3if.clk);   
    end
    sm3if.msg_inpt_lst_i    = 1'b1;

    //准备最后一个周期的数据
    `ifdef SM3_INPT_DW_32
        sm3if.msg_inpt_vld_byte_i =     unalign_byte_num == 2'd0 ? 4'b1111
                                    :   unalign_byte_num == 2'd1 ? 4'b1000
                                    :   unalign_byte_num == 2'd2 ? 4'b1100
                                    :   unalign_byte_num == 2'd3 ? 4'b1110
                                    :   4'b1111;
        sm3if.msg_inpt_d_i =            unalign_byte_num == 2'd0 ? {DATA_INIT_PTTRN}
                                    :   unalign_byte_num == 2'd1 ? {DATA_INIT_PTTRN[31-: 8], 24'd0}
                                    :   unalign_byte_num == 2'd2 ? {DATA_INIT_PTTRN[31-:16], 16'd0}
                                    :   unalign_byte_num == 2'd3 ? {DATA_INIT_PTTRN[31-:24],  8'd0}
                                    :   DATA_INIT_PTTRN;
    `elsif SM3_INPT_DW_64
        sm3if.msg_inpt_vld_byte_i =     unalign_byte_num == 3'd0 ? 8'b1111_1111
                                    :   unalign_byte_num == 3'd1 ? 8'b1000_0000
                                    :   unalign_byte_num == 3'd2 ? 8'b1100_0000
                                    :   unalign_byte_num == 3'd3 ? 8'b1110_0000
                                    :   unalign_byte_num == 3'd4 ? 8'b1111_0000
                                    :   unalign_byte_num == 3'd5 ? 8'b1111_1000
                                    :   unalign_byte_num == 3'd6 ? 8'b1111_1100
                                    :   unalign_byte_num == 3'd7 ? 8'b1111_1110
                                    :   8'b1111_1111;
        sm3if.msg_inpt_d_i =            unalign_byte_num == 3'd0 ? {DATA_INIT_PTTRN}
                                    :   unalign_byte_num == 3'd1 ? {DATA_INIT_PTTRN[63-: 8], 56'd0}
                                    :   unalign_byte_num == 3'd2 ? {DATA_INIT_PTTRN[63-:16], 48'd0}
                                    :   unalign_byte_num == 3'd3 ? {DATA_INIT_PTTRN[63-:24], 40'd0}
                                    :   unalign_byte_num == 3'd4 ? {DATA_INIT_PTTRN[63-:32], 32'd0}
                                    :   unalign_byte_num == 3'd5 ? {DATA_INIT_PTTRN[63-:40], 24'd0}
                                    :   unalign_byte_num == 3'd6 ? {DATA_INIT_PTTRN[63-:48], 16'd0}
                                    :   unalign_byte_num == 3'd7 ? {DATA_INIT_PTTRN[63-:56],  8'd0}
                                    :   DATA_INIT_PTTRN;
    `endif
    
    @(posedge sm3if.clk);   
    sm3if.msg_inpt_vld_i    = 1'b0;
    sm3if.msg_inpt_lst_i    = 1'b0;
    sm3if.msg_inpt_d_i      = DATA_INIT_PTTRN;
    
endtask //automatic

//产生用于比较的图样，最后 512bit 输出
function automatic void golden_pttrn_gntr(
    ref     bit [7:0]   gldn_pttrn[63:0],
    input   bit [60:0]  byte_num
    );
    
    
endfunction

endmodule