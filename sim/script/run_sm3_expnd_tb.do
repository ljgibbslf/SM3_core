#////////////////////////////////////////////////////////////////////////////////
# Author:        ljgibbs / lf_gibbs@163.com
# Create Date: 2020/07/26 
# Design Name: sm3
# Module Name: run_sm3_expnd_tb
# Description:
#      运行 sm3 扩展模块 tb 的 Modelsim 脚本
#          - 使用相对路径
#          - 使用库 sm3_core
# Revision:
# Revision 0.01 - File Created
#////////////////////////////////////////////////////////////////////////////////

vlib sm3_core

vlog -64 -incr -work sm3_core  "+incdir+../../rtl/inc" \
"../../rtl/*.v" \
"../../rtl/util/*.v" \

vlog -64 -incr -sv -work sm3_core  "+incdir+../../rtl/inc" \
"../../rtl/if/*.sv" \
"../../rtl/wrppr/*.sv" \
"../tb/*.sv" \
"../sim_rtl/*.sv" \

vsim -voptargs="+acc" -t 1ps   -L unisims_ver -L unimacro_ver -L secureip -lib sm3_core sm3_core.tb_sm3_expnd_top;

add wave *

view wave
view structure
view signals
log -r /*

restart -f;run 2us
