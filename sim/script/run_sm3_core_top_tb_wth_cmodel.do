#////////////////////////////////////////////////////////////////////////////////
# Author:        ljgibbs / lf_gibbs@163.com
# Create Date: 2020/07/29 
# Design Name: sm3
# Module Name: run_sm3_core_top_tb_wth_cmodel
# Description:
#      运行 sm3 顶层 tb 的 Modelsim 脚本
#          - 使用相对路径
#          - 使用库 sm3_core
#          - 与 C 模型结果比较
# Revision:
# Revision 0.01 - File Created
#////////////////////////////////////////////////////////////////////////////////

vlib sm3_core

vlog -64 -incr -work sm3_core  "+incdir+../../rtl/inc" \
"../../rtl/*.v" \
"../../rtl/util/*.v" \

vlog -64 -incr -sv -work sm3_core  "+incdir+../../rtl/inc" \
"../../rtl/if/*.sv" \
"../../rtl/*.sv" \
"../../rtl/wrppr/*.sv" \
"../sim_rtl/*.sv" \

#compile tb & c model
vlog -work sm3_core "+incdir+../../rtl/inc" \
-sv -dpiheader ../../c_model/dpiheader.h\
 ../tb/tb_sm3_core_top.sv \
 ../../c_model/sm3.c

vsim -voptargs="+acc" -t 1ps   -L unisims_ver -L unimacro_ver -L secureip -lib sm3_core sm3_core.tb_sm3_core_top;
add wave *

view wave
view structure
view signals
log -r /*

add wave -position insertpoint sim:/tb_sm3_core_top/U_sm3_core_top/U_sm3_pad_core/*

restart -f;run 200us
