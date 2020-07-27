//////////////////////////////////////////////////////////////////////////////////
// Author:        ljgibbs / lf_gibbs@163.com
// Create Date: 2020/07/27 
// Design Name: sm3
// Module Name: sm3_cmprss_core
// Description:
//      SM3 迭代压缩模块-SM3 迭代压缩核心单元
//      输入位宽：INPT_DW1 定义，支持32/64bit
//      输出位宽：与输入位宽对应
//      特性：在 64bit 位宽下，采用二度展开结构（暂未）
// Dependencies: 
//      inc/sm3_cfg.v
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////
module sm3_cmprss_core (
    input                       clk,
    input                       rst_n,

    input  [`INPT_DW1:0]        expnd_inpt_wj_i,                    
    input  [`INPT_DW1:0]        expnd_inpt_wjj_i,                    
    input                       expnd_inpt_lst_i,                  
    input                       expnd_inpt_vld_i,    

    output                      expnd_inpt_ena_o,

    output [255:0]              sm3_cmprss_otpt_res_o,
    output                      sm3_cmprss_otpt_vld_o
);