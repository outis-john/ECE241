# ModelSim test for screenscanner. Run from the game folder:  do screenscanner.do
# Uses the real maze_rom (Quartus IP), so it needs the altera_mf library.
vlib work
vlog +incdir+. maze_rom.v screenscanner.v tb_screenscanner.v
vsim -L altera_mf_ver tb_screenscanner
log {/*}
add wave -radix unsigned /tb_screenscanner/dut/x /tb_screenscanner/dut/y
add wave -radix binary   /tb_screenscanner/dut/tile
add wave -radix unsigned /tb_screenscanner/x_out /tb_screenscanner/y_out
add wave -radix binary   /tb_screenscanner/color_out
add wave /tb_screenscanner/write_out /tb_screenscanner/done
run -all
