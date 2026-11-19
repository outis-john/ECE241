# ModelSim test for tile_painter: paint tile (1,2) in red.
# Expect: write_out high for 256 clocks, x_out 16..31, y_out 32..47, then one done pulse.
vlib work
vlog tile_painter.v
vsim tile_painter
log {/*}
add wave {/*}

# 50 MHz-style clock: period 20 ns
force {clk} 0 0ns, 1 10ns -r 20ns

# reset for 2 clocks
force {resetn} 0
force {start} 0
force {tx} 10#1
force {ty} 10#2
force {color_in} 2#111000000
run 40ns

# release reset, then a one-clock start pulse
force {resetn} 1
run 20ns
force {start} 1
run 20ns
force {start} 0

# 256 pixels + a few extra clocks
run 5300ns
