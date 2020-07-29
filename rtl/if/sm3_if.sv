`timescale 1ns / 1ps
// `include "../inc/sm3_cfg"
`include "sm3_cfg.v"
//////////////////////////////////////////////////////////////////////////////////
// Author:        ljgibbs / lf_gibbs@163.com
// Create Date: 2020/07/22 
// Design Name: sm3
// Module Name: sm3_if
// Description:
//      SM3 总线定义
//          分为 pad/expnd/cmprss/monitor/top 类型
// Dependencies: 
//      inc/sm3_cfg.v
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////
interface sm3_if;
logic                       clk;
logic                       rst_n;
logic [`INPT_DW1:0]         msg_inpt_d;
logic [`INPT_BYTE_DW1:0]    msg_inpt_vld_byte;
logic                       msg_inpt_vld;
logic                       msg_inpt_lst;
logic                       msg_inpt_rdy;

logic                       pad_otpt_ena;
logic [`INPT_DW1:0]         pad_otpt_d;
logic                       pad_otpt_lst;
logic                       pad_otpt_vld;

logic [`INPT_DW1:0]         expnd_otpt_wj; 
logic [`INPT_DW1:0]         expnd_otpt_wjj; 
logic                       expnd_otpt_lst;
logic                       expnd_otpt_vld; 

logic [255:0]               cmprss_otpt_res;
logic                       cmprss_otpt_vld;

modport PAD (
    input clk,rst_n,msg_inpt_d,msg_inpt_vld_byte,msg_inpt_vld,msg_inpt_lst,pad_otpt_ena,
    output msg_inpt_rdy,pad_otpt_d,pad_otpt_lst,pad_otpt_vld 
);

modport MONITOR (
    input clk,rst_n,msg_inpt_d,msg_inpt_vld_byte,msg_inpt_vld,msg_inpt_lst,pad_otpt_ena,
    msg_inpt_rdy,pad_otpt_d,pad_otpt_lst,pad_otpt_vld 
);

modport EXPND (
    input clk,rst_n,pad_otpt_d,pad_otpt_lst,pad_otpt_vld,
    output expnd_otpt_wj,expnd_otpt_wjj,expnd_otpt_lst,expnd_otpt_vld,pad_otpt_ena
);

modport CMPRSS (
    input clk,rst_n,expnd_otpt_wj,expnd_otpt_wjj,expnd_otpt_lst,expnd_otpt_vld,
    output cmprss_otpt_res,cmprss_otpt_vld
);

modport TOP (
    input clk,rst_n,msg_inpt_d,msg_inpt_vld_byte,msg_inpt_vld,msg_inpt_lst,
    output msg_inpt_rdy,cmprss_otpt_res,cmprss_otpt_vld
);

endinterface //sm3_if