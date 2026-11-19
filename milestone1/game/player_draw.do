# ModelSim test for player_draw (uses tile_painter). Run from the game folder:
#   do player_draw.do
vlib work
vlog +incdir+. tile_painter.v player_draw.v tb_player_draw.v
vsim tb_player_draw
log {/*}
add wave -divider inputs
add wave -radix unsigned /tb_player_draw/maze_done /tb_player_draw/p1_x /tb_player_draw/p1_y /tb_player_draw/p2_x /tb_player_draw/p2_y
add wave -divider player_draw
add wave -radix unsigned /tb_player_draw/dut/state /tb_player_draw/dut/step
add wave /tb_player_draw/paint_start
add wave -radix unsigned /tb_player_draw/paint_tx /tb_player_draw/paint_ty
add wave -radix binary /tb_player_draw/paint_color
add wave /tb_player_draw/paint_done
add wave -divider tile_painter
add wave /tb_player_draw/write_out
add wave -radix unsigned /tb_player_draw/x_out /tb_player_draw/y_out
run -all
