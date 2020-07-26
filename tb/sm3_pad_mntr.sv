`timescale 1ns / 1ps
`include "sm3_cfg.v"
//////////////////////////////////////////////////////////////////////////////////
// Author:        ljgibbs / lf_gibbs@163.com
// Create Date: 2020/07/23 
// Design Name: sm3
// Module Name: sm3_pad_mntr
// Description:
//      SM3 填充结果监视器，将填充的最后一块结果与标准结果数组比较
//          接口：sm3_if MONITOR
// Dependencies: 
//      inc/sm3_cfg.v
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////
module sm3_pad_mntr (
    sm3_if.MONITOR sm3if,
    ref bit [31:0]  gldn_pttrn[16]
);

int     total_cnt = 0;
int     ok_cnt = 0;
int     fail_cnt = 0;


logic [511:0]   sm3_pad_lst_blk_reg;
logic [511:0]   sm3_gldn_pttrn_reg;

logic           sm3_pad_reg_shft;
logic           sm3_pad_reg_init;
logic           sm3_pad_reg_cmpr;

always @(posedge sm3if.clk or negedge sm3if.rst_n) begin
    if(~sm3if.rst_n) begin
        sm3_pad_reg_cmpr    <=  1'b0;
        sm3_pad_reg_init    <=  1'b0;
    end else begin
        sm3_pad_reg_cmpr    <=  sm3if.pad_otpt_lst;
        sm3_pad_reg_init    <=  sm3_pad_reg_cmpr;
    end
end
assign          sm3_pad_reg_shft    =  sm3if.pad_otpt_vld;

//shift reg pad data 
always @(posedge sm3if.clk or negedge sm3if.rst_n) begin
    if(~sm3if.rst_n) begin
        sm3_pad_lst_blk_reg    <=  512'b0;
    end else if(sm3_pad_reg_shft)begin
        `ifdef SM3_INPT_DW_32
            sm3_pad_lst_blk_reg    <=  {sm3_pad_lst_blk_reg[(511-32):0],sm3if.pad_otpt_d};
        `elsif SM3_INPT_DW_64
            sm3_pad_lst_blk_reg    <=  {sm3_pad_lst_blk_reg[(511-64):0],sm3if.pad_otpt_d};
        `endif
    end else if(sm3_pad_reg_init)begin
        sm3_pad_lst_blk_reg    <=  512'b0;
    end
end

//compare with golden pattern
always @(posedge sm3_pad_reg_cmpr) begin
    total_cnt++;
    $display("Mess:@%0t:result compare %d times",$time,total_cnt);
    foreach(gldn_pttrn[i])
        sm3_gldn_pttrn_reg[511 -32*i-:32] = gldn_pttrn[i];//do a copy to a ref array .hhh
    
    // if (sm3_gldn_pttrn_reg == sm3_pad_lst_blk_reg) begin
    //     ok_cnt++;
    //     $display("Mess:@%0t:check ok and ok %d times",$time,ok_cnt);
    // end else begin
    //     fail_cnt++;
    //     $display("Err:@%0t:check fail and fail %d times",$time,fail_cnt);
    //     $stop;
    // end

    cmpr_a1:assert (sm3_gldn_pttrn_reg == sm3_pad_lst_blk_reg) 
    begin
        ok_cnt++;
        $display("Mess:@%0t:check ok and ok %d times",$time,ok_cnt);
    end
    else begin
        fail_cnt++;
        $display("Err:@%0t:check fail and fail %d times",$time,fail_cnt);
        $stop;
    end
end


endmodule
