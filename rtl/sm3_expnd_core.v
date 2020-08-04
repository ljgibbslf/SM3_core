`timescale 1ns / 1ps
`include "sm3_cfg.v"
//////////////////////////////////////////////////////////////////////////////////
// Author:        ljgibbs / lf_gibbs@163.com
// Create Date: 2020/07/26 
// Design Name: sm3
// Module Name: sm3_expnd_core
// Description:
//      SM3 扩展模块-SM3 扩展核心单元
//      输入位宽：INPT_DW1 定义，支持32/64bit
//      输出位宽：与输入位宽对应
//      特性：预载寄存器（68->65clk(32b)/66->65clk(64b)）,目前仅支持32bit，默认开启
// Dependencies: 
//      inc/sm3_cfg.v
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////
module sm3_expnd_core (
    input                       clk,
    input                       rst_n,

    input   [`INPT_DW1:0]       pad_inpt_d_i,
    input                       pad_inpt_vld_i,
    input                       pad_inpt_lst_i,

    output                      pad_inpt_rdy_o,

    output  [`INPT_DW1:0]       expnd_otpt_wj_o,                    
    output  [`INPT_DW1:0]       expnd_otpt_wjj_o,                    
    output                      expnd_otpt_lst_o,                  
    output                      expnd_otpt_vld_o                    
);

//每时钟输入的数据字数量 32bit位宽：1 64bit位宽：2
`ifdef SM3_INPT_DW_32
    localparam [1:0]            INPT_WORD_NUM               =   2'd1;
`elsif SM3_INPT_DW_64
    localparam [1:0]            INPT_WORD_NUM               =   2'd2;
`endif

localparam                  WORD_INPT_NUM       = 512 / 32;//16
localparam [5:0]            WORD_EXPND_ROUND    = 52;//(68 - 16)

`ifdef SM3_EXPND_PRE_LOAD_REG
    localparam              PRE_BUFF_N = 4;
`endif

//字扩展电路
wire [31:0]             word_wj_expand;
wire [31:0]             word_wjj_otpt;
wire [31:0]             word_wj_expand_tmp_1;
wire [31:0]             word_wj_expand_tmp_2;

//字扩展电路（64bit）
`ifdef SM3_INPT_DW_64
    wire [31:0]             word_wj_expand_w1;
    wire [31:0]             word_wjj_otpt_w1;
    wire [31:0]             word_wj_expand_tmp_1_w1;
    wire [31:0]             word_wj_expand_tmp_2_w1;
`endif

wire                    word_exp_push_reg_ena;  //字拓展，并压入寄存器组使能

//寄存器组 reg
reg [31:0]              word_buff [15:0];   //16字缓冲区  缓存16个32位字
wire                    word_buff_shft_ena;  
wire[31:0]              word_buff_new_push; //寄存器组，新入组变量

//64bit 新增的一个扩展字
`ifdef SM3_INPT_DW_64
    wire[31:0]              word_buff_new_push_w1;
`endif

//预缓冲区
`ifdef SM3_EXPND_PRE_LOAD_REG
    reg [31:0]              word_buff_nb_pre [3:0];//4字 下一字预缓存区
    wire                    word_buff_rpd_shft_ena;  
    wire                    word_buff_nb_pre_shft_ena;  
`endif

//预缓冲区数据数量计数
`ifdef SM3_EXPND_PRE_LOAD_REG
    reg [1:0]               word_buff_nb_pre_cntr;
    wire                    word_buff_nb_pre_cntr_add;
    wire                    word_buff_nb_pre_cntr_clr; 
`endif

//原始字输入计数
reg [3:0]               msg_blk_word_inpt_cntr;  
wire                    msg_blk_word_inpt_cntr_add;
wire                    msg_blk_word_inpt_cntr_clr;

//字扩展输出计数，指本数据块中扩展电路的扩展字输出数量
reg [5:0]               msg_blk_word_exp_cntr;  
wire                    msg_blk_word_exp_cntr_add;
wire                    msg_blk_word_exp_cntr_clr;

//消息扩展主状态机
`define STT_W 8
`define STT_W1 `STT_W - 1

reg [`STT_W1:0]   state;
reg [`STT_W1:0]   nxt_state;

localparam IDLE                     = `STT_W'h1;
localparam INPT_ORGN_5W             = `STT_W'h2;//输入5个原始字w0-w4到寄存器组中
localparam INPT_OTPT                = `STT_W'h4;//输入剩下的11个原始字w5-w15，并输出11对扩展字
localparam EXP_OTPT                 = `STT_W'h8;//扩展并输出扩展字,直至扩展得到第48个扩展字w63
localparam EXP_OTPT_PRE_INPT        = `STT_W'h10;//当w64生成后，开始预接收下一消息块前3个消息字 wn0-wn2，消息字写入预存储寄存器
localparam EXP_OTPT_FIN             = `STT_W'h20;//扩展以及输出结束（输出最后一对扩展字）,接收下一消息块的第4个消息字 wn3,判断预存储器中数据数量
localparam WAT_PRE_INPT_FIN         = `STT_W'h40;//若预存储器数据数量>0 但 <4,等待预寄存器存储完成 4 字
localparam RPD_SHFT                 = `STT_W'h80;//快速移位原始数据,128b位宽的形式，包括预存储寄存器

//SM3填充消息输入反压逻辑
wire                    pad_inpt_d_inpt_rdy;

//消息最后一块标记信号
reg                     msg_lst_blk_flg;
wire                    msg_lst_blk_flg_ena;
wire                    msg_lst_blk_flg_clr;

//SM3填充消息输入反压逻辑，仅在 EXP_OTPT 状态下仅进行扩展，不提供输入
assign                  pad_inpt_d_inpt_rdy = (  state == IDLE 
                                        ||    state == INPT_ORGN_5W
                                        ||    (state == INPT_OTPT && ~(nxt_state   ==  EXP_OTPT))//提前一个周期置低输入有效信号     
                                        ||    state == EXP_OTPT_PRE_INPT     
                                        ||    state == EXP_OTPT_FIN        
                                        ||    state == WAT_PRE_INPT_FIN    
                                        ||    state == RPD_SHFT            
                                        ) ;
  
//原始字输入计数
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        msg_blk_word_inpt_cntr              <= 4'b0;
    end else if(msg_blk_word_inpt_cntr_add)begin
        msg_blk_word_inpt_cntr              <= msg_blk_word_inpt_cntr + INPT_WORD_NUM;
    end else if(msg_blk_word_inpt_cntr_clr)begin
        msg_blk_word_inpt_cntr              <= 4'b0;
    end
end
assign                  msg_blk_word_inpt_cntr_add  = pad_inpt_vld_i; //计数输入消息字
assign                  msg_blk_word_inpt_cntr_clr  = 1'b0; //0-f 对应 16 个消息字，计数自清

//字扩展输出计数
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        msg_blk_word_exp_cntr              <= 6'b0;
    end else if(msg_blk_word_exp_cntr_clr)begin
        msg_blk_word_exp_cntr              <= 6'b0;
    end else if(msg_blk_word_exp_cntr_add)begin
        msg_blk_word_exp_cntr              <= msg_blk_word_exp_cntr + INPT_WORD_NUM;
    end
end
assign                  msg_blk_word_exp_cntr_add  = word_exp_push_reg_ena;//字扩展并移入寄存器使能
assign                  msg_blk_word_exp_cntr_clr  = msg_blk_word_exp_cntr == WORD_EXPND_ROUND;//完成所有扩展次数后清除计数器

`ifdef SM3_EXPND_PRE_LOAD_REG
    //预缓冲区数据数量计数
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            word_buff_nb_pre_cntr              <= 2'b0;
        end else if(word_buff_nb_pre_cntr_add)begin
            word_buff_nb_pre_cntr              <= word_buff_nb_pre_cntr + INPT_WORD_NUM;
        end else if(word_buff_nb_pre_cntr_clr)begin
            word_buff_nb_pre_cntr              <= 2'b0;
        end
    end
    assign                  word_buff_nb_pre_cntr_add  = (  state == EXP_OTPT_PRE_INPT 
                                                        ||  state == EXP_OTPT_FIN  
                                                        ||  state == WAT_PRE_INPT_FIN  
                                                        ) && pad_inpt_vld_i;//预输入状态下的外部数据输入有效
    assign                  word_buff_nb_pre_cntr_clr  = state == RPD_SHFT ;//预输入寄存器该状态下被移出
`endif

//消息最后一块标记信号
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        msg_lst_blk_flg              <= 1'b0;
    end else if(msg_lst_blk_flg_ena)begin
        msg_lst_blk_flg              <= 1'b1;
    end else if(msg_lst_blk_flg_clr)begin
        msg_lst_blk_flg              <= 1'b0;
    end
end

assign                  msg_lst_blk_flg_ena  = pad_inpt_lst_i;
assign                  msg_lst_blk_flg_clr  = expnd_otpt_lst_o;

//消息扩展主状态机
always @(*) begin
    case (state)
        IDLE: begin
            if(pad_inpt_vld_i)
                nxt_state   =   INPT_ORGN_5W;
            else
                nxt_state   =   IDLE;
        end
        INPT_ORGN_5W:begin
            if(msg_blk_word_inpt_cntr == 4'd4 && pad_inpt_vld_i) 
                nxt_state   =   INPT_OTPT;//输入前 5 个原始字后，开始一边输入，一边输出
            else
                nxt_state   =   INPT_ORGN_5W;
        end
        INPT_OTPT:begin
            if(msg_blk_word_inpt_cntr == (WORD_INPT_NUM - INPT_WORD_NUM) && pad_inpt_vld_i) 
                nxt_state   =   EXP_OTPT;//输入所有 16 个原始字后，开始向寄存器组输入扩展字
            else
                nxt_state   =   INPT_OTPT;
        end
        EXP_OTPT:begin
            if(msg_blk_word_exp_cntr == 6'd48) 
                nxt_state   =   EXP_OTPT_PRE_INPT; //在生成w63（第48个扩展字后）后，允许下一个块预输入 
            else
                nxt_state   =   EXP_OTPT;
        end
        EXP_OTPT_PRE_INPT:begin
            if(msg_blk_word_exp_cntr == (WORD_EXPND_ROUND - INPT_WORD_NUM)) 
                nxt_state   =   EXP_OTPT_FIN; //在生成51个扩展字后,转入最后一个扩展字 
            else
                nxt_state   =   EXP_OTPT_PRE_INPT;
        end
        EXP_OTPT_FIN:begin
            `ifdef SM3_EXPND_PRE_LOAD_REG
                if(word_buff_nb_pre_cntr == 2'd0 && ~pad_inpt_vld_i) 
                    nxt_state   =   IDLE; //扩展期间无预缓存字，转为idle，等待下次输入
                else if((word_buff_nb_pre_cntr == 3'd4 - INPT_WORD_NUM) && pad_inpt_vld_i)
                    nxt_state   =   RPD_SHFT;//4 个预缓存字，转入 RPD_SHFT
                else 
                    nxt_state   =   WAT_PRE_INPT_FIN;//存在预缓存字，转入 WAT_PRE_INPT_FIN，等待条件满足
            `else
                nxt_state   =   IDLE;
            `endif
        end
        WAT_PRE_INPT_FIN:begin
            `ifdef SM3_EXPND_PRE_LOAD_REG
                if((word_buff_nb_pre_cntr == 3'd4 - INPT_WORD_NUM) && pad_inpt_vld_i) 
                    nxt_state   =   RPD_SHFT; //4 个预缓存字，转入 RPD_SHFT
                else 
                    nxt_state   =   WAT_PRE_INPT_FIN;//存在预缓存字，转入WAT_PRE_INPT_FIN
            `else
                nxt_state   =   IDLE;
            `endif
        end
        RPD_SHFT:begin
            `ifdef SM3_EXPND_PRE_LOAD_REG
                if(pad_inpt_vld_i) 
                    nxt_state   =   INPT_OTPT; //5个原始字输入完毕，开始一边输入，一边输出
                else
                    nxt_state   =   RPD_SHFT;//等待第5个原始字
            `else
                nxt_state   =   IDLE;
            `endif
        end
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

//扩展电路
assign                  word_wj_expand_tmp_1        =   word_buff[0] ^ word_buff[7] ^ {word_buff[13][16:0],word_buff[13][31:17]};
assign                  word_wj_expand_tmp_2        =   {word_wj_expand_tmp_1 ^ {word_wj_expand_tmp_1[16:0],word_wj_expand_tmp_1[31:17]} 
                                                                                ^ {word_wj_expand_tmp_1[8:0],word_wj_expand_tmp_1[31:9]}};

assign                  word_wj_expand              =   word_wj_expand_tmp_2 ^ word_buff[10] ^ {word_buff[3][24:0],word_buff[3][31:25]};

`ifdef SM3_INPT_DW_64
    assign                  word_wj_expand_tmp_1_w1        =   word_buff[1] ^ word_buff[8] ^ {word_buff[14][16:0],word_buff[14][31:17]};
    assign                  word_wj_expand_tmp_2_w1        =   {word_wj_expand_tmp_1_w1 ^ {word_wj_expand_tmp_1_w1[16:0],word_wj_expand_tmp_1_w1[31:17]} 
                                                                                    ^ {word_wj_expand_tmp_1_w1[8:0],word_wj_expand_tmp_1_w1[31:9]}};

    assign                  word_wj_expand_w1              =   word_wj_expand_tmp_2_w1 ^ word_buff[11] ^ {word_buff[4][24:0],word_buff[4][31:25]};
`endif

`ifdef SM3_INPT_DW_32
    assign                  word_wjj_otpt                 =   word_buff[11] ^ word_buff[15];
`elsif SM3_INPT_DW_64
    assign                  word_wjj_otpt                 =   word_buff[10] ^ word_buff[14];
    assign                  word_wjj_otpt_w1              =   word_buff[11] ^ word_buff[15];
`endif

    
//扩展电路输出至主寄存器使能
assign                  word_exp_push_reg_ena       =   (state == EXP_OTPT         
                                                    ||   state == EXP_OTPT_PRE_INPT
                                                    ||   state == EXP_OTPT_FIN     
                                                        );

// 根据当前扩展轮数，确定补充进缓冲区的数据类型：原始数据(0-15) 扩展数据(16-67) 0( >67)
assign                  word_buff_new_push          =   (state == IDLE
                                                    ||   state == INPT_ORGN_5W
                                                    ||   state == RPD_SHFT
                                                    ||   state == INPT_OTPT 
                                                    `ifdef SM3_INPT_DW_32
                                                        ) ? pad_inpt_d_i[31:0] : 
                                                    `elsif SM3_INPT_DW_64
                                                        ) ? pad_inpt_d_i[63:32] : 
                                                    `endif
                                                        word_exp_push_reg_ena ? word_wj_expand : 
                                                        32'd0;

`ifdef SM3_INPT_DW_64
    assign                  word_buff_new_push_w1   =   (state == IDLE
                                                    ||   state == INPT_ORGN_5W
                                                    ||   state == RPD_SHFT
                                                    ||   state == INPT_OTPT 
                                                        ) ? pad_inpt_d_i[31:0] : 
                                                        word_exp_push_reg_ena ? word_wj_expand_w1 : 
                                                        32'd0;
`endif

//消息缓冲区 push
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin : buff_init
        integer i;
        for ( i = 0 ; i < WORD_INPT_NUM; i = i + 1) begin:buff_init
            word_buff[i]                <=      32'd0;          
        end
    end
    else if(word_buff_shft_ena)begin : buff_shift // w0 <- w1; w1 <- w2;....w15 <- w_new
        integer i;
        `ifdef SM3_INPT_DW_32
            for ( i = WORD_INPT_NUM - 1 ; i > 0 ; i = i - 1) begin
                word_buff[i-1]                  <=      word_buff[i];    
            end
            word_buff[15]                   <=      word_buff_new_push;  
        `elsif SM3_INPT_DW_64
            for ( i = (WORD_INPT_NUM / INPT_WORD_NUM)- 1 ; i > 0 ; i = i - 1) begin
                word_buff[2*i-1]                    <=      word_buff[2*i+1];    
                word_buff[2*(i-1)]                  <=      word_buff[2*i];    
            end
            {word_buff[14],word_buff[15]}                   <=      {word_buff_new_push,word_buff_new_push_w1};    
        `endif
    end
    `ifdef SM3_EXPND_PRE_LOAD_REG
        else if(word_buff_rpd_shft_ena)begin : buff_rpd_shift //快速移位阶段
            `ifdef SM3_INPT_DW_32
                word_buff[15]                   <=      pad_inpt_d_i;      
                word_buff[14]                   <=      word_buff_nb_pre[3];      
                word_buff[13]                   <=      word_buff_nb_pre[2];      
                word_buff[12]                   <=      word_buff_nb_pre[1];      
                word_buff[11]                   <=      word_buff_nb_pre[0]; 
            `elsif SM3_INPT_DW_64
                {word_buff[14],word_buff[15]}   <=      pad_inpt_d_i;      
                word_buff[13]                   <=      word_buff_nb_pre[2];      
                word_buff[12]                   <=      word_buff_nb_pre[3];      
                word_buff[11]                   <=      word_buff_nb_pre[0];      
                word_buff[10]                   <=      word_buff_nb_pre[1];  
            `endif
                 
        end
    `endif
end

assign                  word_buff_shft_ena      =   (state == IDLE && pad_inpt_vld_i)
                                                ||  (state == INPT_ORGN_5W  && pad_inpt_vld_i)
                                                ||  (state == INPT_OTPT     && pad_inpt_vld_i)
                                                ||  state == EXP_OTPT 
                                                ||  state == EXP_OTPT_PRE_INPT 
                                                ||  state == EXP_OTPT_FIN 
                                                ;//寄存器组左移使能 20.5.13 fix

`ifdef SM3_EXPND_PRE_LOAD_REG
    assign                  word_buff_rpd_shft_ena  =   state == RPD_SHFT && pad_inpt_vld_i; //缓存区快速移位使能 

    //消息预缓冲区
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin : pre_buff_init
            integer i;
            for ( i = 0 ; i < PRE_BUFF_N; i = i + 1) begin : pre_buff_init
                word_buff_nb_pre[i]                <=      32'd0;          
            end
        end
        else if(word_buff_nb_pre_shft_ena)begin : pre_buff_shift // wnb0 <- wnb1....wnb3 <- input
            integer i;
            `ifdef SM3_INPT_DW_32
                for ( i = PRE_BUFF_N - 1 ; i > 0 ; i = i - 1) begin
                    word_buff_nb_pre[i-1]                  <=      word_buff_nb_pre[i];    
                end
                word_buff_nb_pre[PRE_BUFF_N - 1]                   <=      pad_inpt_d_i;    
            `elsif SM3_INPT_DW_64
                for ( i = (PRE_BUFF_N / INPT_WORD_NUM)- 1 ; i > 0 ; i = i - 1) begin
                    word_buff_nb_pre[2*i-1]                    <=      word_buff_nb_pre[2*i+1];    
                    word_buff_nb_pre[2*(i-1)]                  <=      word_buff_nb_pre[2*i];    
                end
                {word_buff_nb_pre[PRE_BUFF_N - 1], word_buff_nb_pre[PRE_BUFF_N - 2]}                  <=      pad_inpt_d_i;    
            `endif
        end
    end

    assign                  word_buff_nb_pre_shft_ena   =   (   state == EXP_OTPT_PRE_INPT
                                                            ||  state == EXP_OTPT_FIN 
                                                            ||  state == WAT_PRE_INPT_FIN 
                                                            ) && pad_inpt_vld_i;//预缓冲区移位使能
`endif

//输出控制
`ifdef SM3_INPT_DW_32
    assign                  expnd_otpt_wj_o                =  word_buff[11];// 从倒数第5个寄存器输出
    assign                  expnd_otpt_wjj_o               =  word_wjj_otpt;
`elsif SM3_INPT_DW_64
    assign                  expnd_otpt_wj_o                =  {word_buff[10],word_buff[11]};
    assign                  expnd_otpt_wjj_o               =  {word_wjj_otpt,word_wjj_otpt_w1};
`endif

assign                  expnd_otpt_vld_o        =  (state == INPT_OTPT && pad_inpt_vld_i) //20.5.13 fix   
                                                ||  state == EXP_OTPT         
                                                ||  state == EXP_OTPT_PRE_INPT
                                                ||  state == EXP_OTPT_FIN
                                                    ;
assign                  expnd_otpt_lst_o        =  msg_lst_blk_flg && state == EXP_OTPT_FIN;
assign                  pad_inpt_rdy_o           =  pad_inpt_d_inpt_rdy; //反压控制

//调试打印信息 debug log
`ifdef SM3_EXPND_SIM_DBG
    generate
        always@(posedge clk) begin
            if(expnd_otpt_vld_o)begin
                `ifdef SM3_INPT_DW_32
                    $display("LOG: EXPND WORD %8h | %8h", expnd_otpt_wj_o[31:0],expnd_otpt_wjj_o[31:0],);
                `elsif SM3_INPT_DW_64
                    $display("LOG: EXPND WORD wj[63:32]:%8h | wj[31:0]:%8h | wjj[63:32]:%8h | wjj[31:0]:%8h"  
                                                                    ,expnd_otpt_wj_o[63:32]
                                                                    ,expnd_otpt_wj_o[31:0]
                                                                    ,expnd_otpt_wjj_o[63:32]
                                                                    ,expnd_otpt_wjj_o[31:0]
                                                                    );
                `endif    
            end	
        end
    endgenerate
`endif
endmodule
