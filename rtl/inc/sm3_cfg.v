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

//模块调试开关-----------------------------
`ifdef  DESIGN_SIM
    //`define SM3_PAD_SIM_DBG
    // `define SM3_EXPND_SIM_DBG
    `define SM3_CMPRS_SIM_DBG
    // `define SM3_CMPRS_SIM_FILE_LOG
`endif

//C模型相关设置----------------------------
// `define C_MODEL_SELF_TEST

//定义 SM3 输入位宽------------------------
// `define SM3_INPT_DW_32
`ifndef  SM3_INPT_DW_32
    `define SM3_INPT_DW_64
`endif

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

//定义 SM3 迭代压缩中的加法方式-----------------------
//直接使用加法符，使工具推断
//`define SM3_CMPRSS_DIRECT_ADD
//显式例化 CSA 加法器 在 SM3_CMPRSS_DIRECT_ADD 未定义时有效
`ifndef  SM3_CMPRSS_DIRECT_ADD
    `define SM3_CMPRSS_CSA_ADD
`endif

//定义仿真器 define simulator
// Modelsim_10_5(windows), default 
// EpicSim (Linux)
//`define EPICSIM
`ifndef EPICSIM
    `define MODELSIM_10_5
`endif

//定义是否使用 C 语言参考模型(DPI)
//define using C reference model or not
`define C_MODEL_ENABLE

//定义是否 dump 波形
//define dump wave in VCD or not
//`define VCD_DUMP_ENABLE