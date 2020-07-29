`timescale 1ns / 1ps
// `include "./inc/sm3_cfg.v"
`include "sm3_cfg.v"
//////////////////////////////////////////////////////////////////////////////////
// Author:        ljgibbs / lf_gibbs@163.com
// Create Date: 2020/07/19 
// Design Name: sm3
// Module Name: sm3_pad_core
// Description:
//      SM3 填充模块-SM3 填充核心单元
//      输入位宽：INPT_DW1 定义，支持32/64
//      输出位宽：与输入位宽一致
// Dependencies: 
//      inc/sm3_cfg.v
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////
module sm3_pad_core (
    input                       clk,
    input                       rst_n,

    input   [`INPT_DW1:0]       msg_inpt_d_i,
    input   [`INPT_BYTE_DW1:0]  msg_inpt_vld_byte_i,
    input                       msg_inpt_vld_i,
    input                       msg_inpt_lst_i,

    input                       pad_otpt_ena_i,

    output                      msg_inpt_rdy_o,

    output  [`INPT_DW1:0]       pad_otpt_d_o,                    
    output                      pad_otpt_lst_o,                  
    output                      pad_otpt_vld_o                    
);

localparam [15:0]           PAD_BLK_WD_NUM              =   16;
localparam [15:0]           PAD_BLK_BIT_LEN_WD_NUM      =   2;
localparam [15:0]           PAD_BLK_WD_NUM_INIT         =   PAD_BLK_WD_NUM - PAD_BLK_BIT_LEN_WD_NUM;
localparam [ 3:0]           PAD_BLK_WD_NUM_WTHT_LEN     =   PAD_BLK_WD_NUM - PAD_BLK_BIT_LEN_WD_NUM;

//每时钟输入的数据字数量 32bit位宽：1 64bit位宽：2
`ifdef SM3_INPT_DW_32
    localparam [1:0]            INPT_WORD_NUM               =   2'd1;
`elsif SM3_INPT_DW_64
    localparam [1:0]            INPT_WORD_NUM               =   2'd2;
`endif

//最后一个数据的填充图样
`ifdef SM3_INPT_DW_32
    reg  [31:0]             lst_data_pad_mask;
`elsif SM3_INPT_DW_64
    reg  [63:0]             lst_data_pad_mask;
`endif

//对输入数据打拍  beat inpt signals
reg     [`INPT_DW1:0]       msg_inpt_d_r1;
reg     [`INPT_BYTE_DW1:0]  msg_inpt_vld_byte_r1;
reg                         msg_inpt_vld_r1;
reg                         msg_inpt_lst_r1;

//输入字数统计 count inpt words(32bit)
reg [15:0]                  inpt_wd_cntr;
wire                        inpt_wd_cntr_add;
wire                        inpt_wd_cntr_clr;

//输入字节数统计 count inpt byte
wire[60:0]                  inpt_byte_cntr;

//填充字数统计 count padded words
reg [4:0]                   pad_00_wd_cntr;
wire                        pad_00_wd_cntr_inpt_updt; //随数据输入递减 dec with data inpt
wire                        pad_00_wd_cntr_pad_updt;  //随数据填充递减 dec with pad data
wire                        pad_00_wd_cntr_rld;       //对于新消息，装填计数器 reload cntr for new msg   

//输入比特长度 count inpt bit length
wire [63:0]                 inpt_bit_cntr;

//填充后数据输出使能
wire                        pad_otpt_ena;

//统计最后一个数据的有效字节数  cnt vld byte of the last inpt data
reg  [3:0]                  inpt_vld_byte_cnt;
reg  [3:0]                  inpt_vld_byte_cnt_lat;
wire                        inpt_vld_byte_cmplt;                                 

integer i;

//流程状态机
`define STT_W 10
`define STT_W1 `STT_W - 1

reg [`STT_W1:0]   state;
reg [`STT_W1:0]   nxt_state;

localparam IDLE                     = `STT_W'h1;
localparam INPT_DATA                = `STT_W'h2;
localparam INPT_PAD_LST_DATA        = `STT_W'h4;
localparam PAD_10_DATA              = `STT_W'h8;
localparam PAD_00_DATA              = `STT_W'h10;
localparam PAD_LEN_H                = `STT_W'h20;
localparam PAD_LEN_L                = `STT_W'h40;
localparam ADD_BLK_PAD_00           = `STT_W'h80;
localparam PAD_00_WAT_NEW_BLK       = `STT_W'h100;
localparam PAD_10_WAT_NEW_BLK       = `STT_W'h200;

//对输入数据打拍  beat inpt signals
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        msg_inpt_d_r1               <=  `INPT_DW'b0;
        msg_inpt_vld_byte_r1        <=  'b0;
        msg_inpt_vld_r1             <=  1'b0;
        msg_inpt_lst_r1             <=  1'b0;
    end else begin
        msg_inpt_d_r1               <=  msg_inpt_d_i;
        msg_inpt_vld_byte_r1        <=  msg_inpt_vld_byte_i;
        msg_inpt_vld_r1             <=  msg_inpt_vld_i;
        msg_inpt_lst_r1             <=  msg_inpt_lst_i;
    end
end

//生成最后一个数据的填充图样
always @(*) begin
    `ifdef SM3_INPT_DW_32
        case (inpt_vld_byte_cnt)
            4'd0: lst_data_pad_mask      =   32'h8000_0000;
            4'd1: lst_data_pad_mask      =   32'h0080_0000;
            4'd2: lst_data_pad_mask      =   32'h0000_8000;
            4'd3: lst_data_pad_mask      =   32'h0000_0080;
            4'd4: lst_data_pad_mask      =   32'h0000_0000;
            default: lst_data_pad_mask      =   32'h8000_0000;
        endcase
    `elsif SM3_INPT_DW_64
        case (inpt_vld_byte_cnt)
            4'd0: lst_data_pad_mask      =   64'h8000_0000_0000_0000;
            4'd1: lst_data_pad_mask      =   64'h0080_0000_0000_0000;
            4'd2: lst_data_pad_mask      =   64'h0000_8000_0000_0000;
            4'd3: lst_data_pad_mask      =   64'h0000_0080_0000_0000;
            4'd4: lst_data_pad_mask      =   64'h0000_0000_8000_0000;
            4'd5: lst_data_pad_mask      =   64'h0000_0000_0080_0000;
            4'd6: lst_data_pad_mask      =   64'h0000_0000_0000_8000;
            4'd7: lst_data_pad_mask      =   64'h0000_0000_0000_0080;
            4'd8: lst_data_pad_mask      =   64'h0000_0000_0000_0000;
            default: lst_data_pad_mask      =   64'h8000_0000_0000_0000;
        endcase
    `endif
end


//统计最后一个数据的有效字节数 
always @(*) begin
    inpt_vld_byte_cnt = 4'b0;
    for(i = 0;i <= `INPT_BYTE_DW1;i=i+1) begin
        inpt_vld_byte_cnt = inpt_vld_byte_cnt + msg_inpt_vld_byte_r1[i];
    end
end

assign                  inpt_vld_byte_cmplt =   inpt_vld_byte_cnt == 4 * INPT_WORD_NUM;

//在last信号，锁存 inpt_vld_byte_cnt
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        inpt_vld_byte_cnt_lat   <=  4'd0;
    end
    else if(msg_inpt_lst_r1)begin
        inpt_vld_byte_cnt_lat   <=  inpt_vld_byte_cnt;
    end
end

//输入字数统计
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        inpt_wd_cntr              <= 16'b0;
    end else if(inpt_wd_cntr_add)begin
        inpt_wd_cntr              <= inpt_wd_cntr + INPT_WORD_NUM;
    end else if(inpt_wd_cntr_clr)begin
        inpt_wd_cntr              <= 16'b0;
    end
end
assign                  inpt_wd_cntr_add    = msg_inpt_vld_r1;
assign                  inpt_wd_cntr_clr    = pad_otpt_lst_o;

assign                  inpt_byte_cntr      =   {inpt_wd_cntr,2'd0} + inpt_vld_byte_cnt_lat - {INPT_WORD_NUM,2'd0};
assign                  inpt_bit_cntr       =   {inpt_byte_cntr,3'd0};

//填充字数统计
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        pad_00_wd_cntr              <= PAD_BLK_WD_NUM_INIT;//16-2=14
    end else if(pad_00_wd_cntr_inpt_updt)begin
        pad_00_wd_cntr              <= pad_00_wd_cntr == INPT_WORD_NUM 
                                    ? PAD_BLK_WD_NUM 
                                    : pad_00_wd_cntr - INPT_WORD_NUM;
    end else if(pad_00_wd_cntr_rld)begin
        pad_00_wd_cntr              <= PAD_BLK_WD_NUM_INIT;
    end else if(pad_00_wd_cntr_pad_updt)begin
        pad_00_wd_cntr              <= pad_00_wd_cntr - INPT_WORD_NUM;
    end
end
assign                  pad_00_wd_cntr_inpt_updt    = msg_inpt_vld_r1;
assign                  pad_00_wd_cntr_pad_updt     = state == PAD_10_DATA || state == PAD_00_DATA || state == ADD_BLK_PAD_00;
assign                  pad_00_wd_cntr_rld          = pad_otpt_lst_o;

//实现流程状态机
always @(*) begin
    case (state)
        IDLE: begin
            if(msg_inpt_vld_i && ~msg_inpt_lst_i)
                nxt_state   =   INPT_DATA;
            else if(msg_inpt_lst_i)//fix 数据周期为1的情况
                nxt_state   =   INPT_PAD_LST_DATA;
            else
                nxt_state   =   IDLE;
        end
        INPT_DATA: begin //直接输出输入数据，无需填充
            if(msg_inpt_lst_i)
                nxt_state   =   INPT_PAD_LST_DATA;
            else
                nxt_state   =   INPT_DATA;
        end
        INPT_PAD_LST_DATA: begin//根据最后一个输入数据的情况，确定填充策略
            if(inpt_vld_byte_cmplt) begin
                // if(inpt_wd_cntr[3:0] == 4'd0 && ~(inpt_wd_cntr == 16'd0))begin
                if(inpt_wd_cntr[3:0] == PAD_BLK_WD_NUM - INPT_WORD_NUM)begin
                    nxt_state   =   PAD_10_WAT_NEW_BLK;//填充以'1'为首的新块
                end else begin//本块中填1
                    nxt_state   =   PAD_10_DATA;
                end
            end
            else if(inpt_wd_cntr[3:0] == PAD_BLK_WD_NUM_WTHT_LEN - INPT_WORD_NUM)//14 - 1/2
                nxt_state   =   PAD_LEN_H;
            else if(inpt_wd_cntr[3:0] < PAD_BLK_WD_NUM_WTHT_LEN - INPT_WORD_NUM)
                nxt_state   =   PAD_00_DATA;
            else if(inpt_wd_cntr[3:0] > PAD_BLK_WD_NUM_WTHT_LEN - INPT_WORD_NUM)
                `ifdef SM3_INPT_DW_32
                    if(inpt_wd_cntr[3:0] == PAD_BLK_WD_NUM_WTHT_LEN)
                        nxt_state   =   ADD_BLK_PAD_00;//（32位专用）为当前块填充最后一个全0双字
                    else
                        nxt_state   =   PAD_00_WAT_NEW_BLK;
                `elsif SM3_INPT_DW_64
                    nxt_state   =   PAD_00_WAT_NEW_BLK;
                `endif
        end
        PAD_10_DATA: begin//填充由1个1和若干个0组成的数据
            if(inpt_wd_cntr[3:0] < PAD_BLK_WD_NUM_WTHT_LEN - INPT_WORD_NUM)//14-2(64b)
                nxt_state   =   PAD_00_DATA;//直接填0
            else if(inpt_wd_cntr[3:0] == PAD_BLK_WD_NUM_WTHT_LEN - INPT_WORD_NUM)
                nxt_state   =   PAD_LEN_H;//填充长度
            else begin //>PAD_BLK_WD_NUM_WTHT_LEN - INPT_WORD_NUM
                `ifdef SM3_INPT_DW_32
                    if(inpt_wd_cntr[3:0] == PAD_BLK_WD_NUM_WTHT_LEN)
                        nxt_state   =   ADD_BLK_PAD_00;//（32位专用）为当前块填充最后一个全0双字
                    else
                        nxt_state   =   PAD_00_WAT_NEW_BLK;
                `elsif SM3_INPT_DW_64
                    nxt_state   =   PAD_00_WAT_NEW_BLK;
                `endif
            end
        end
        ADD_BLK_PAD_00:begin//在新增的填充块之前补一个0字（32位专用）
            nxt_state   =   PAD_00_WAT_NEW_BLK;
        end
        PAD_00_WAT_NEW_BLK: 
            if(~pad_otpt_ena_i) //等待上一块处理完毕后 开始新的一块输出
                nxt_state   =   PAD_00_WAT_NEW_BLK;
            else
                nxt_state   =   PAD_00_DATA;
        PAD_10_WAT_NEW_BLK: //与 PAD_00_WAT_NEW_BLK 状态的区别在于，新块跳转 PAD_10_DATA 添加 10 
            if(~pad_otpt_ena_i) 
                nxt_state   =   PAD_10_WAT_NEW_BLK;
            else
                nxt_state   =   PAD_10_DATA;
        PAD_00_DATA: //填充全 0 数据
            if(pad_00_wd_cntr == INPT_WORD_NUM)
                nxt_state   =   PAD_LEN_H;
            else
                nxt_state   =   PAD_00_DATA;
        PAD_LEN_H: //填充比特长度的高32位/填充整个比特长度
        `ifdef SM3_INPT_DW_32
            nxt_state   =   PAD_LEN_L;
        `elsif SM3_INPT_DW_64
            nxt_state   =   IDLE;
        `endif
        PAD_LEN_L: 
            nxt_state   =   IDLE;
        default: 
            nxt_state   =   IDLE;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        state   <=  `STT_W'b1;
    else begin
        state   <=  nxt_state;
    end  
end



assign                      pad_otpt_ena    =     state == PAD_10_DATA          
                                            ||    state == PAD_00_DATA          
                                            ||    state == PAD_LEN_H          
                                            ||    state == PAD_LEN_L          
                                            ||    state == ADD_BLK_PAD_00 ;                                                             
//输出控制
`ifdef SM3_INPT_DW_32
    assign                      pad_otpt_d_o    =   state == PAD_10_DATA ? 32'h8000_0000:
                                                    state == INPT_PAD_LST_DATA? msg_inpt_d_r1 | lst_data_pad_mask:
                                                    state == PAD_00_DATA || state == ADD_BLK_PAD_00? 32'h0:
                                                    state == PAD_LEN_H ? inpt_bit_cntr[63-:32]: 
                                                    state == PAD_LEN_L ? inpt_bit_cntr[31-:32]:
                                                    msg_inpt_d_r1;
    assign                      pad_otpt_lst_o      =   state == PAD_LEN_L;
`elsif SM3_INPT_DW_64
    assign                      pad_otpt_d_o    =   state == PAD_10_DATA ? 64'h8000_0000_0000_0000:
                                                    state == INPT_PAD_LST_DATA? msg_inpt_d_r1 | lst_data_pad_mask:
                                                    state == PAD_00_DATA || state == ADD_BLK_PAD_00? 64'h0:
                                                    state == PAD_LEN_H ? inpt_bit_cntr: 
                                                    msg_inpt_d_r1;
    assign                      pad_otpt_lst_o      =   state == PAD_LEN_H;
`endif

assign                      pad_otpt_vld_o      =   msg_inpt_vld_r1 || pad_otpt_ena;
assign                      msg_inpt_rdy_o      =   pad_otpt_ena_i && (state == IDLE || state == INPT_DATA);

endmodule