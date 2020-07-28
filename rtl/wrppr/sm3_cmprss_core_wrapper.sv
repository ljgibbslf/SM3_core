`timescale 1ns / 1ps
`include "sm3_cfg.v"
//////////////////////////////////////////////////////////////////////////////////
// Author:        ljgibbs / lf_gibbs@163.com
// Create Date: 2020/07/26 
// Design Name: sm3
// Module Name: sm3_cmprss_core_wrapper
// Description:
//      sm3_cmprss_core 的 SV 封装
//          封装 sm3_if 总线接口，类型为 CMPRSS
// Dependencies: 
//      inc/sm3_cfg.v
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////
module sm3_cmprss_core_wrapper (
    sm3_if.CMPRSS sm3if
);

sm3_expnd_core sm3_cmprss_core(
    .clk                        (sm3if.clk                    ),
    .rst_n                      (sm3if.rst_n                  ),

    .expnd_inpt_wj_i            ( sm3if.expnd_otpt_wj                  ),
    .expnd_inpt_wjj_i           ( sm3if.expnd_otpt_wjj                  ),
    .expnd_inpt_lst_i           ( sm3if.expnd_otpt_lst                  ),
    .expnd_inpt_vld_i           ( sm3if.expnd_otpt_vld                  ),

    .cmprss_otpt_res_o          ( sm3if.cmprss_otpt_res               ),
    .cmprss_otpt_vld_o          ( sm3if.cmprss_otpt_vld               )
);   
    
endmodule