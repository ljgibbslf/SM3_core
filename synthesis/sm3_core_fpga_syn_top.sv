`timescale 1ns / 1ps
`include "sm3_cfg.v"
//////////////////////////////////////////////////////////////////////////////////
// Author:        ljgibbs / lf_gibbs@163.com
// Create Date: 2020/08/04 
// Design Name: sm3
// Module Name: sm3_core_fpga_syn_top
// Description:
//      SM3 FPGA 综合顶层，端口连接至 VIO 
// Dependencies: 
//      inc/sm3_cfg.v
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////
module sm3_core_syn_top (
    input clk,
    input rst_n
);

wire [63:0]            sm3_data;
wire [ 7:0]            sm3_data_vld_byte;


//interface
sm3_if sm3if();

//sm3_core_top
sm3_core_top U_sm3_core_top(
    sm3if
);

//xilinx vio ip
vio_sm3_syn U_vio_sm3_syn (
  .clk(clk),                // input wire clk
  .probe_in0(sm3if.msg_inpt_rdy),    // input wire [0 : 0] probe_in0
  .probe_in1(sm3if.cmprss_otpt_vld),    // input wire [0 : 0] probe_in1
  .probe_in2(sm3if.cmprss_otpt_res),    // input wire [255 : 0] probe_in2
  .probe_out0(sm3if.msg_inpt_lst),  // output wire [0 : 0] probe_out0
  .probe_out1(sm3if.msg_inpt_vld),  // output wire [0 : 0] probe_out1
  .probe_out2(sm3_data_vld_byte),  // output wire [7 : 0] probe_out2
  .probe_out3(sm3_data)  // output wire [63 : 0] probe_out3
);

`ifdef SM3_INPT_DW_32
    assign      sm3if.msg_inpt_d        =   sm3_data[31:0];
    assign      sm3if.msg_inpt_vld_byte =   sm3_data_vld_byte[3:0];
`elsif SM3_INPT_DW_64
    assign      sm3if.msg_inpt_d        =   sm3_data;
    assign      sm3if.msg_inpt_vld_byte =   sm3_data_vld_byte;
`endif

assign      sm3if.clk       =   clk;
assign      sm3if.rst_n     =   rst_n;

    
endmodule