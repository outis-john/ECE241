# ModelSim test for player_draw + box_painter (8x8 smooth drawing). Run:  do player_draw.do
vlib work
vlog +incdir+. box_painter.v player_draw.v tb_player_draw.v
vsim tb_player_draw
add wave -radix unsigned /tb_player_draw/p1_x /tb_player_draw/p1_y /tb_player_draw/p2_x /tb_player_draw/p2_y
add wave -radix unsigned /tb_player_draw/dut/state /tb_player_draw/dut/step
add wave /tb_player_draw/paint_start /tb_player_draw/excl_en
add wave -radix unsigned /tb_player_draw/paint_x /tb_player_draw/paint_y
add wave -radix binary   /tb_player_draw/paint_color
add wave /tb_player_draw/write_out /tb_player_draw/paint_done
add wave -radix unsigned /tb_player_draw/x_out /tb_player_draw/y_out
run -all
