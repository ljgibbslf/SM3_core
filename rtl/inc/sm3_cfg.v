`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author:        ljgibbs / lf_gibbs@163.com
// Create Date: 2020/07/19 
// Design Name: sm3
// Module Name: sm3_cfg
// Description:
//      SM3 模块配置信息
// Dependencies: 
//      
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////
//定义设计阶段-----------------------------
`define DESIGN_SIM
// `define DESIGN_SYNT

//模块调试开关
`ifdef  DESIGN_SIM
    //`define SM3_PAD_SIM_DBG
    `define SM3_EXPND_SIM_DBG
    `define SM3_CMPRS_SIM_DBG
`endif

//定义 SM3 输入位宽------------------------
`define SM3_INPT_DW_32
// `define SM3_INPT_DW_64

`ifdef SM3_INPT_DW_32
    `define     INPT_DW    32
`elsif SM3_INPT_DW_64
    `define     INPT_DW    64
`endif

// `define INPT_DW1        (INPT_DW - 1)
`define INPT_DW1        (`INPT_DW - 1)
`define INPT_BYTE_DW1   (`INPT_DW/8 - 1)
`define INPT_BYTE_DW    (`INPT_BYTE_DW1 + 1)

//定义 SM3 输出位宽-------------------------
// `define SM3_OTPT_DW_32
`define SM3_OTPT_DW_64
// `define SM3_OTPT_DW_128
// `define SM3_OTPT_DW_256

`ifdef SM3_OTPT_DW_32
    `define     OTPT_DW    32
`elsif SM3_OTPT_DW_64
    `define     OTPT_DW    64
`elsif SM3_OTPT_DW_128
    `define     OTPT_DW    128
`elsif SM3_OTPT_DW_256
    `define     OTPT_DW    256
`endif

`define OTPT_DW1 (OTPT_DW - 1)

//定义 SM3 字扩展模式-----------------------
`define SM3_EXPND_PRE_LOAD_REG