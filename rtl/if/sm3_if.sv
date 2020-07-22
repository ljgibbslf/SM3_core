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
//          分为 pad/expnd/cmprss/monitor 类型
// Dependencies: 
//      inc/sm3_cfg.v
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////
interface sm3_if;
    logic                       clk;
    logic                       rst_n;

    logic [`INPT_DW1:0]         msg_inpt_d_i;
    logic [`INPT_BYTE_DW1:0]    msg_inpt_vld_byte_i;
    logic                       msg_inpt_vld_i;
    logic                       msg_inpt_lst_i;

    logic                       pad_otpt_ena_i;

    logic                       msg_inpt_rdy_o;
    logic                       pad_otpt_d_o;
    logic                       pad_otpt_lst_o;
    logic                       pad_otpt_vld_o;

    modport PAD (
        input clk,rst_n,msg_inpt_d_i,msg_inpt_vld_byte_i,msg_inpt_vld_i,msg_inpt_lst_i,pad_otpt_ena_i,
        output msg_inpt_rdy_o,pad_otpt_d_o,pad_otpt_lst_o,pad_otpt_vld_o 
    );
endinterface //sm3_if