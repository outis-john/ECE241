# ModelSim test for player_move (smooth movement). Run from this folder:  do player_move.do
# Uses maze_rom_sim.v (simulation copy of the maze ROM, reads maze_tiles.txt).
vlib work
vlog maze_rom_sim.v player_move.v tb_player_move.v
vsim tb_player_move
add wave -radix unsigned /tb_player_move/tick /tb_player_move/w /tb_player_move/a /tb_player_move/s /tb_player_move/d
add wave -radix unsigned /tb_player_move/p1_x /tb_player_move/p1_y /tb_player_move/p1_facing
add wave -radix unsigned /tb_player_move/p2_x /tb_player_move/p2_y
add wave -radix unsigned /tb_player_move/dut/state /tb_player_move/dut/cur1 /tb_player_move/dut/mov1
run -all
