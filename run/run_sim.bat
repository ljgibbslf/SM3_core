@echo off
REM ****************************************************************************
REM Vivado (TM) v2018.3 (64-bit)
REM adapt by ljgibbs / lf_gibbs@163.com for design:sm3_core
REM 
REM Filename    : run_sim.bat
REM Simulator   : Mentor Graphics ModelSim Simulator
REM Description : Script for compiling the simulation design source files
REM
REM Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
REM
REM usage: run_sim.bat
REM
REM ****************************************************************************
set bin_path=C:\modeltech64_10.5\win64
call %bin_path%/vsim -do "do {run_sm3_expnd_tb.do}" -l run_sim.log

if "%errorlevel%"=="1" goto END
if "%errorlevel%"=="0" goto SUCCESS
:END
exit 1
:SUCCESS
exit 0