`timescale 1ns / 1ps
`include "sm3_cfg.v"
//////////////////////////////////////////////////////////////////////////////////
// Author:        ljgibbs / lf_gibbs@163.com
// Create Date: 2020/07/22 
// Design Name: sm3
// Module Name: sm3_pad_core_wrapper
// Description:
//      sm3_pad_core 封装
//          封装 sm3_if 总线接口，类型为 PAD
// Dependencies: 
//      inc/sm3_cfg.v
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////
module sm3_pad_core_wrapper (
    sm3_if.PAD sm3if
);

sm3_pad_core U_sm3_pad_core(
    .clk                    (sm3if.clk                    ),
    .rst_n                  (sm3if.rst_n                  ),

    .msg_inpt_d_i           (sm3if.msg_inpt_d_i           ),
    .msg_inpt_vld_byte_i    (sm3if.msg_inpt_vld_byte_i    ),
    .msg_inpt_vld_i         (sm3if.msg_inpt_vld_i         ),
    .msg_inpt_lst_i         (sm3if.msg_inpt_lst_i         ),

    .pad_otpt_ena_i         (sm3if.pad_otpt_ena_i         ),

    .msg_inpt_rdy_o         (sm3if.msg_inpt_rdy_o         ),

    .pad_otpt_d_o           (sm3if.pad_otpt_d_o           ),
    .pad_otpt_lst_o         (sm3if.pad_otpt_lst_o         ),
    .pad_otpt_vld_o         (sm3if.pad_otpt_vld_o         )
);   
    
endmodule