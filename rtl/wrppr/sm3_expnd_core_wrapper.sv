`timescale 1ns / 1ps
`include "sm3_cfg.v"
//////////////////////////////////////////////////////////////////////////////////
// Author:        ljgibbs / lf_gibbs@163.com
// Create Date: 2020/07/26 
// Design Name: sm3
// Module Name: sm3_expnd_core_wrapper
// Description:
//      sm3_expnd_core 的 SV 封装
//          封装 sm3_if 总线接口，类型为 EXPND
// Dependencies: 
//      inc/sm3_cfg.v
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////
module sm3_expnd_core_wrapper (
    sm3_if.EXPND sm3if
);

sm3_expnd_core U_sm3_expnd_core(
    .clk                        (sm3if.clk                    ),
    .rst_n                      (sm3if.rst_n                  ),

    .pad_inpt_d_i            ( sm3if.pad_inpt_d                    ),
    .pad_inpt_vld_i          ( sm3if.pad_inpt_vld                  ),
    .pad_inpt_lst_i          ( sm3if.pad_inpt_lst                  ),
    .expnd_otpt_ena_i        ( sm3if.expnd_otpt_ena                ),

    .pad_inpt_rdy_o          ( sm3if.pad_otpt_ena                  ),
    .expnd_otpt_wj_o         ( sm3if.expnd_otpt_wj                 ),
    .expnd_otpt_wjj_o        ( sm3if.expnd_otpt_wjj                ),
    .expnd_otpt_lst_o        ( sm3if.expnd_otpt_lst                ),
    .expnd_otpt_vld_o        ( sm3if.expnd_otpt_vld                )
);   
    
endmodule