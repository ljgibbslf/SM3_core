`timescale 1ns / 1ps
`include "sm3_cfg.v"
//////////////////////////////////////////////////////////////////////////////////
// Author:        ljgibbs / lf_gibbs@163.com
// Create Date: 2020/07/29
// Design Name: sm3
// Module Name: tb_sm3_core_top
// Description:
//      SM3 顶层 testbench
//          测试 sm3_core_top 
// Dependencies: 
//      inc/sm3_cfg.v
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Pass random test with c model
//////////////////////////////////////////////////////////////////////////////////
module tb_sm3_core_top (                 
);

`ifdef SM3_INPT_DW_32
    localparam [1:0]            INPT_WORD_NUM               =   2'd1;
`elsif SM3_INPT_DW_64
    localparam [1:0]            INPT_WORD_NUM               =   2'd2;
`endif

//import c reference function
import "DPI-C" function void sm3_c(input int len,input bit[7:0] data[],output bit[31:0] res[]);

int i;
bit [31:0]  urand_num;
bit [7:0] data[1050];
bit [31:0] res[8];

int stat_test_cnt;
int stat_ok_cnt;
int stat_fail_cnt;
bit [60:0]  sm3_inpt_byte_num;

//interface
sm3_if sm3if();

//sm3_core_top
sm3_core_top U_sm3_core_top(
    sm3if
);

initial begin
    sm3if.clk                     = 0;
    sm3if.rst_n                   = 0;
    sm3if.msg_inpt_d            = 0;
    sm3if.msg_inpt_vld_byte     = 4'b1111;
    sm3if.msg_inpt_vld          = 0;
    sm3if.msg_inpt_lst          = 0;

    #100;
    sm3if.rst_n                   =1;

    while (1) begin
        //complete random
        //sm3_inpt_byte_num = $urandom % (61'h1fff_ffff_ffff_ffff) + 1;
        //medium random
        // sm3_inpt_byte_num = $urandom % (64*100) + 1;

        `ifdef C_MODEL_SELF_TEST
            sm3_inpt_byte_num = 64;
        `else
            sm3_inpt_byte_num = ($urandom % 128 + 1 + 4);
        `endif

        @(posedge sm3if.clk);
        task_rndm_inpt_cmpr_cmodel(sm3_inpt_byte_num);
        @(posedge sm3if.clk);
    end
    

end

always #5 sm3if.clk = ~sm3if.clk; 

//产生填充模块输入，随机输入，并与 c 语言参考模型比较
task automatic task_rndm_inpt_cmpr_cmodel(
    input bit [60:0] byte_num
);
    bit [2:0]   unalign_byte_num;
    bit [55:0]  data_inpt_clk_num;

    //根据总线位宽计算数据输入时钟数与非对齐的数据数量
    `ifdef SM3_INPT_DW_32
        unalign_byte_num    =   byte_num[1:0];
        data_inpt_clk_num   =   unalign_byte_num == 0 ? byte_num[60:2] : byte_num[60:2] + 1'b1;
    `elsif SM3_INPT_DW_64
        unalign_byte_num    =   byte_num[2:0];
        data_inpt_clk_num   =   unalign_byte_num == 0 ? byte_num[60:3] : byte_num[60:3] + 1'b1;
    `endif


    // 初始化数组同时产生逻辑激励
    for(i = 0 ; i < data_inpt_clk_num - 1 ; i++)begin
        sm3if.msg_inpt_vld          = 1;
        sm3if.msg_inpt_vld_byte     = 4'b1111;

        `ifdef C_MODEL_SELF_TEST
            urand_num =  32'h61626364;
        `else
            urand_num =  ($urandom);
        `endif

        {data[4*i],data[4*i+1],data[4*i+2],data[4*i+3]} = urand_num;
        sm3if.msg_inpt_d = urand_num;
        @(posedge sm3if.clk);
        // $display("SV array b4 %d:%x", i,urand_num);
        sm3if.msg_inpt_vld = 0;
        @(posedge sm3if.clk);
        wait(sm3if.msg_inpt_rdy == 1'b1);
        @(posedge sm3if.clk);
    end
    sm3if.msg_inpt_vld = 1;

    //准备最后一个周期的数据
    
    `ifdef C_MODEL_SELF_TEST
        urand_num =  32'h61626364;
    `else
        urand_num =  ($urandom);
    `endif
    
    {data[4*i],data[4*i+1],data[4*i+2],data[4*i+3]} = urand_num;

    sm3if.msg_inpt_lst = 1;

    `ifdef SM3_INPT_DW_32
        lst_data_gntr_32(sm3if.msg_inpt_d,sm3if.msg_inpt_vld_byte,unalign_byte_num,urand_num);
    `elsif SM3_INPT_DW_64
        lst_data_gntr_64(sm3if.msg_inpt_d,sm3if.msg_inpt_vld_byte,unalign_byte_num,urand_num);
    `endif

    @(posedge sm3if.clk);
    // $display("SV array b4 %d:%x", i,urand_num);
    sm3if.msg_inpt_vld = 0;
    sm3if.msg_inpt_lst = 0;
    // sm3if.msg_inpt_vld_byte     = 4'b1111;

    //调用c语言函数，以开放数组形式传参
    sm3_c(byte_num,data,res);
    //统计信息
    wait(sm3if.cmprss_otpt_vld);
    stat_test_cnt++;
    if(sm3if.cmprss_otpt_res == 
        {res[0],res[1],res[2],res[3],res[4],res[5],res[6],res[7]})
    begin
        stat_ok_cnt++;
        $display("Res Correct!");
    end else begin
        stat_fail_cnt++;
        $display("Res Wrong with sm3_inpt_byte_num:%d!",sm3_inpt_byte_num);
        $stop;
    end
    $display("Test %d times OK %d times,Fail %d times",stat_test_cnt,stat_ok_cnt,stat_fail_cnt);
    
    //打印返回的摘要值
    foreach(res[i])
        $display("SV array af %d:%x", i,res[i]);
endtask //automatic


//产生填充模块输入，采用示例输入 'abc' 32bit 输入
task automatic task_pad_inpt_gntr_exmpl0_32();

    
    sm3if.msg_inpt_vld      = 1'b1;
    sm3if.msg_inpt_lst      = 1'b1;
    sm3if.msg_inpt_d        = 32'h6162_6300;
    sm3if.msg_inpt_vld_byte = 4'b1110;
    @(posedge sm3if.clk);   
    sm3if.msg_inpt_vld    = 1'b0;
    sm3if.msg_inpt_lst    = 1'b0;
    sm3if.msg_inpt_d      = 0;
    
endtask //automatic

//产生填充模块输入，采用示例输入 512bit 重复的 'abcd' 32bit 输入
task automatic task_pad_inpt_gntr_exmpl1_32();

    sm3if.msg_inpt_vld      = 1'b1;
    sm3if.msg_inpt_d        = 32'h6162_6364;
    sm3if.msg_inpt_vld_byte = 4'b1111;
    repeat(15)begin
        @(posedge sm3if.clk);   
    end
    sm3if.msg_inpt_lst      = 1'b1;
    @(posedge sm3if.clk);   
    sm3if.msg_inpt_vld    = 1'b0;
    sm3if.msg_inpt_lst    = 1'b0;
    sm3if.msg_inpt_d      = 0;
    
endtask //automatic

//32bit 生成最后一个周期数据
`ifdef SM3_INPT_DW_32
function automatic void lst_data_gntr_32(
    ref logic [31:0]  lst_data, 
    ref logic [ 3:0]  lst_vld_byte,
    input bit [2:0]   unalign_byte_num,
    input logic [31:0]rndm_data
    );
        lst_vld_byte                =   unalign_byte_num == 2'd0 ? 4'b1111
                                    :   unalign_byte_num == 2'd1 ? 4'b1000
                                    :   unalign_byte_num == 2'd2 ? 4'b1100
                                    :   unalign_byte_num == 2'd3 ? 4'b1110
                                    :   4'b1111;
        lst_data                    =   unalign_byte_num == 2'd0 ? {rndm_data}
                                    :   unalign_byte_num == 2'd1 ? {rndm_data[31-: 8], 24'd0}
                                    :   unalign_byte_num == 2'd2 ? {rndm_data[31-:16], 16'd0}
                                    :   unalign_byte_num == 2'd3 ? {rndm_data[31-:24],  8'd0}
                                    :   rndm_data;
    
endfunction
`elsif SM3_INPT_DW_64
//64bit 生成最后一个周期数据
function automatic void lst_data_gntr_64(
    ref logic [63:0]  lst_data, 
    ref logic [ 7:0]  lst_vld_byte,
    input bit [3:0]   unalign_byte_num,
    input logic [31:0]rndm_data
    );
        lst_vld_byte =                  unalign_byte_num == 3'd0 ? 8'b1111_1111
                                    :   unalign_byte_num == 3'd1 ? 8'b1000_0000
                                    :   unalign_byte_num == 3'd2 ? 8'b1100_0000
                                    :   unalign_byte_num == 3'd3 ? 8'b1110_0000
                                    :   unalign_byte_num == 3'd4 ? 8'b1111_0000
                                    :   unalign_byte_num == 3'd5 ? 8'b1111_1000
                                    :   unalign_byte_num == 3'd6 ? 8'b1111_1100
                                    :   unalign_byte_num == 3'd7 ? 8'b1111_1110
                                    :   8'b1111_1111;
        lst_data =                      unalign_byte_num == 3'd0 ? {rndm_data}
                                    :   unalign_byte_num == 3'd1 ? {rndm_data[63-: 8], 56'd0}
                                    :   unalign_byte_num == 3'd2 ? {rndm_data[63-:16], 48'd0}
                                    :   unalign_byte_num == 3'd3 ? {rndm_data[63-:24], 40'd0}
                                    :   unalign_byte_num == 3'd4 ? {rndm_data[63-:32], 32'd0}
                                    :   unalign_byte_num == 3'd5 ? {rndm_data[63-:40], 24'd0}
                                    :   unalign_byte_num == 3'd6 ? {rndm_data[63-:48], 16'd0}
                                    :   unalign_byte_num == 3'd7 ? {rndm_data[63-:56],  8'd0}
                                    :   rndm_data;
    
endfunction
`endif


endmodule