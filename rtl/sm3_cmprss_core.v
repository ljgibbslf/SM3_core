`timescale 1ns / 1ps
`include "sm3_cfg.v"
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

    output [255:0]              cmprss_otpt_res_o,
    output                      cmprss_otpt_vld_o
);

//每时钟输入的数据字数量 32bit位宽：1 64bit位宽：2
`ifdef SM3_INPT_DW_32
    localparam [1:0]            INPT_WORD_NUM               =   2'd1;
`elsif SM3_INPT_DW_64
    localparam [1:0]            INPT_WORD_NUM               =   2'd2;
`endif

localparam  [6:0]           CMPRSS_RND_NUM = 7'd64;

//A-H 字寄存器
reg		[31 : 0]	reg_a;
reg		[31 : 0]	reg_b;
reg		[31 : 0]	reg_c;
reg		[31 : 0]	reg_d;
reg		[31 : 0]	reg_e;
reg		[31 : 0]	reg_f;
reg		[31 : 0]	reg_g;
reg		[31 : 0]	reg_h;
reg		[31 : 0]	reg_tj;
reg		[5  : 0]	reg_cmprss_round;

reg                 cmprss_round_sm_16;

//结果寄存器
reg                 sm3_res_valid;
reg                 sm3_res_valid_r1;
reg  [255:0]        sm3_res;

reg                 cmprss_blk_res_finish;

//A-H 字运算中间值
wire	[31 : 0]	reg_a_new;
wire	[31 : 0]	reg_b_new;
wire	[31 : 0]	reg_c_new;
wire	[31 : 0]	reg_d_new;
wire	[31 : 0]	reg_e_new;
wire	[31 : 0]	reg_f_new;
wire	[31 : 0]	reg_g_new;
wire	[31 : 0]	reg_h_new;

`ifdef SM3_INPT_DW_64
    wire	[31 : 0]	reg_a_mid;
    wire	[31 : 0]	reg_b_mid;
    wire	[31 : 0]	reg_c_mid;
    wire	[31 : 0]	reg_d_mid;
    wire	[31 : 0]	reg_e_mid;
    wire	[31 : 0]	reg_f_mid;
    wire	[31 : 0]	reg_g_mid;
    wire	[31 : 0]	reg_h_mid;

    //两轮运算的 tj 值
    wire	[31 : 0]	reg_tj_rnd_odd;
    wire	[31 : 0]	reg_tj_rnd_even;
`endif

//块迭代标志
wire                cmprss_new_round_valid;
wire                cmprss_blk_start;  
wire                cmprss_blk_finish; 

//对输入的 wj 值打拍或者分离
reg                 sm3_wj_wjj_vld_r;
reg                 sm3_wj_wjj_lst_r;

`ifdef SM3_INPT_DW_32
    reg     [31:0]      wj_rnd_r;
    reg     [31:0]      wjj_rnd_r;
`elsif SM3_INPT_DW_64
    reg     [31:0]      wj_rnd_odd_r;
    reg     [31:0]      wjj_rnd_odd_r;
    reg     [31:0]      wj_rnd_even_r;
    reg     [31:0]      wjj_rnd_even_r;
`endif

//输入每数据块所属数据字计数
reg     [5:0]       inpt_wrd_of_blk_cntr;
wire                inpt_wrd_of_blk_cntr_add;
wire                inpt_wrd_of_blk_cntr_clr;

//管理tj寄存器
always @(posedge clk or negedge rst_n) begin
    if(~rst_n |cmprss_blk_res_finish) begin
        reg_tj          <=  32'h79cc4519;
    end
    else if(sm3_wj_wjj_vld_r)begin
        if(reg_cmprss_round == 6'd16 - INPT_WORD_NUM)
            reg_tj          <=  32'h9d8a7a87;
        
        else begin
            `ifdef SM3_INPT_DW_32
                reg_tj          <=  {reg_tj[30:0],reg_tj[31]};
            `elsif SM3_INPT_DW_64 //每次循环左移两位
                reg_tj          <=  {reg_tj[29:0],reg_tj[31:30]};
            `endif
        end
    end
end

`ifdef SM3_INPT_DW_64
    //两轮运算的 tj 值
    assign  	reg_tj_rnd_odd      =   {reg_tj[30:0],reg_tj[31]};
    assign  	reg_tj_rnd_even     =   reg_tj;
`endif

//对输入的 wj 值打拍或者分离
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        sm3_wj_wjj_vld_r    <=   1'b0;
        sm3_wj_wjj_lst_r    <=   1'b0;        
    end
    else begin
        sm3_wj_wjj_vld_r    <=   expnd_inpt_vld_i;
        sm3_wj_wjj_lst_r    <=   expnd_inpt_lst_i;       
    end
end

`ifdef SM3_INPT_DW_32
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            wj_rnd_r        <=   32'd0;
            wjj_rnd_r       <=   32'd0;       
        end
        else begin
            wj_rnd_r        <=   expnd_inpt_wj_i;
            wjj_rnd_r       <=   expnd_inpt_wjj_i;     
        end
    end
    
`elsif SM3_INPT_DW_64
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            wj_rnd_odd_r    <=   32'd0;
            wjj_rnd_odd_r   <=   32'd0;       
            wj_rnd_even_r   <=   32'd0;       
            wjj_rnd_even_r  <=   32'd0;       
        end
        else begin
            {wj_rnd_even_r,wj_rnd_odd_r}    <=   expnd_inpt_wj_i;
            {wjj_rnd_even_r,wjj_rnd_odd_r}  <=   expnd_inpt_wjj_i;    
        end
    end
    
`endif

//标记最后一块
assign              cmprss_new_round_valid  =   sm3_wj_wjj_vld_r;  
assign              cmprss_blk_finish       =   inpt_wrd_of_blk_cntr_clr;  

//块运算完成信号 
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        cmprss_blk_res_finish   <=  1'b0;
    end
    else begin
        cmprss_blk_res_finish   <=  inpt_wrd_of_blk_cntr_clr;
    end
end

//输入每数据块所属数据字计数
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        inpt_wrd_of_blk_cntr              <= 6'b0;
    end else if(inpt_wrd_of_blk_cntr_add)begin
        inpt_wrd_of_blk_cntr              <= inpt_wrd_of_blk_cntr + INPT_WORD_NUM;
    end else if(inpt_wrd_of_blk_cntr_clr)begin
        inpt_wrd_of_blk_cntr              <= 6'b0;
    end
end
assign                  inpt_wrd_of_blk_cntr_add  = sm3_wj_wjj_vld_r;
assign                  inpt_wrd_of_blk_cntr_clr  = sm3_wj_wjj_vld_r 
                                                && inpt_wrd_of_blk_cntr == (CMPRSS_RND_NUM - INPT_WORD_NUM);

//压缩迭代轮计数
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        reg_cmprss_round        <=  6'd0;
    end
    else if(cmprss_blk_finish)begin
        reg_cmprss_round        <=  6'd0;
    end
    else if(cmprss_new_round_valid)begin
        reg_cmprss_round        <=  reg_cmprss_round + INPT_WORD_NUM;
    end
end

//产生16轮内标记
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        cmprss_round_sm_16      <= 1'b0;
    end else begin
        cmprss_round_sm_16      <= reg_cmprss_round <  6'd16 - INPT_WORD_NUM; //标识当前小于
    end
end

//寄存器组初值装填与迭代
always @(posedge clk or negedge rst_n) begin
    if((~rst_n) || sm3_res_valid_r1) begin
        reg_a	<=	32'h7380166f;//0;
		reg_b	<=	32'h4914b2b9;//0;
		reg_c	<=	32'h172442d7;//0;
		reg_d	<=	32'hda8a0600;//0;
		reg_e	<=	32'ha96f30bc;//0;
		reg_f	<=	32'h163138aa;//0;
		reg_g	<=	32'he38dee4d;//0;
		reg_h	<=	32'hb0fb0e4e;//0;
    end
    else if(cmprss_new_round_valid)begin
        reg_a	<=	reg_a_new;
		reg_b	<=	reg_b_new;
		reg_c	<=	reg_c_new;
		reg_d	<=	reg_d_new;
		reg_e	<=	reg_e_new;
		reg_f	<=	reg_f_new;
		reg_g	<=	reg_g_new;
		reg_h	<=	reg_h_new;
    end
    else if(cmprss_blk_res_finish)begin
        reg_a	<=	reg_a ^ sm3_res[255-:32];
		reg_b	<=	reg_b ^ sm3_res[223-:32];
		reg_c	<=	reg_c ^ sm3_res[191-:32];
		reg_d	<=	reg_d ^ sm3_res[159-:32];
		reg_e	<=	reg_e ^ sm3_res[127-:32];
		reg_f	<=	reg_f ^ sm3_res[95 -:32];
		reg_g	<=	reg_g ^ sm3_res[63 -:32];
		reg_h	<=	reg_h ^ sm3_res[31 -:32];
    end
end

//消息所属块均计算完毕，输出计算结果
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        sm3_res_valid           <=  1'b0;
        sm3_res_valid_r1        <=  1'b0;
    end
    else begin
        sm3_res_valid           <=  sm3_wj_wjj_lst_r;
        sm3_res_valid_r1        <=  sm3_res_valid;
    end
end

always @(posedge clk or negedge rst_n) begin
    if((~rst_n) || sm3_res_valid_r1) begin
        sm3_res                 <=  {32'h7380166f, 32'h4914b2b9, 32'h172442d7, 32'hda8a0600, 32'ha96f30bc, 32'h163138aa, 32'he38dee4d, 32'hb0fb0e4e};
    end
    else if(cmprss_blk_res_finish)begin
        sm3_res                 <=  {reg_a,reg_b,reg_c,reg_d,reg_e,reg_f,reg_g,reg_h} ^ sm3_res;
    end
end

`ifdef SM3_INPT_DW_32
    sm3_cmprss_ceil_comb U_sm3_cmprss_ceil_comb
    (
        .cmprss_round_sm_16_i   (cmprss_round_sm_16),
        .tj_i                   (reg_tj),
        .reg_a_i                (reg_a),
        .reg_b_i                (reg_b),
        .reg_c_i                (reg_c),
        .reg_d_i                (reg_d),
        .reg_e_i                (reg_e),
        .reg_f_i                (reg_f),
        .reg_g_i                (reg_g),
        .reg_h_i                (reg_h),
        .wj_i                   (wj_rnd_r),
        .wjj_i                  (wjj_rnd_r),
        .reg_a_o                (reg_a_new),
        .reg_b_o                (reg_b_new),
        .reg_c_o                (reg_c_new),
        .reg_d_o                (reg_d_new),
        .reg_e_o                (reg_e_new),
        .reg_f_o                (reg_f_new),
        .reg_g_o                (reg_g_new),
        .reg_h_o                (reg_h_new)
    );

`elsif SM3_INPT_DW_64
    sm3_cmprss_ceil_comb U_sm3_cmprss_ceil_comb
    (
        .cmprss_round_sm_16_i   (cmprss_round_sm_16),
        .tj_i                   (reg_tj_rnd_even),
        .reg_a_i                (reg_a),
        .reg_b_i                (reg_b),
        .reg_c_i                (reg_c),
        .reg_d_i                (reg_d),
        .reg_e_i                (reg_e),
        .reg_f_i                (reg_f),
        .reg_g_i                (reg_g),
        .reg_h_i                (reg_h),
        .wj_i                   (wj_rnd_even_r),
        .wjj_i                  (wjj_rnd_even_r),
        .reg_a_o                (reg_a_mid),
        .reg_b_o                (reg_b_mid),
        .reg_c_o                (reg_c_mid),
        .reg_d_o                (reg_d_mid),
        .reg_e_o                (reg_e_mid),
        .reg_f_o                (reg_f_mid),
        .reg_g_o                (reg_g_mid),
        .reg_h_o                (reg_h_mid)
    );

    sm3_cmprss_ceil_comb U_sm3_cmprss_ceil_comb_1
    (
        .cmprss_round_sm_16_i   (cmprss_round_sm_16),
        .tj_i                   (reg_tj_rnd_odd),
        .reg_a_i                (reg_a_mid),
        .reg_b_i                (reg_b_mid),
        .reg_c_i                (reg_c_mid),
        .reg_d_i                (reg_d_mid),
        .reg_e_i                (reg_e_mid),
        .reg_f_i                (reg_f_mid),
        .reg_g_i                (reg_g_mid),
        .reg_h_i                (reg_h_mid),
        .wj_i                   (wj_rnd_odd_r),
        .wjj_i                  (wjj_rnd_odd_r),
        .reg_a_o                (reg_a_new),
        .reg_b_o                (reg_b_new),
        .reg_c_o                (reg_c_new),
        .reg_d_o                (reg_d_new),
        .reg_e_o                (reg_e_new),
        .reg_f_o                (reg_f_new),
        .reg_g_o                (reg_g_new),
        .reg_h_o                (reg_h_new)
    );
`endif

//输出控制
assign                      cmprss_otpt_vld_o     =   sm3_res_valid_r1;
assign                      cmprss_otpt_res_o     =   sm3_res;

`ifdef SM3_CMPRS_SIM_DBG
    `ifdef SM3_CMPRS_SIM_FILE_LOG
        integer file;
        initial begin:inital_file
            
            file = $fopen("wj.txt","w");
        end
    `endif

    generate
        if(1) begin
            always@(*) begin		
                if(cmprss_otpt_vld_o)
                begin
                    `ifdef SM3_CMPRS_SIM_FILE_LOG
                        $fdisplay(file,"LOG: res : %64h",cmprss_otpt_res_o);
                    `else
                        $display("LOG: res : %64h",cmprss_otpt_res_o);
                    `endif
                    
                end
            end
        end
    endgenerate
`endif

endmodule