#epicsim_sm3_core_top_tb.sh
#@ljgibbs / lf_gibbs@163.com
#usage: script for running tb_sm3_core_top.sv with EpicSim, a opensource simulator

epicsim -g2005-sv -I ../../rtl/inc/  -l ../../sim/tb/tb_sm3_core_top.sv ../../rtl/* ../../rtl/if/sm3_if.sv -s tb_sm3_core_top

