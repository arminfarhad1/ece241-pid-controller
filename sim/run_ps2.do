vlib work
vlog ../ps2_keyboard.v ps2_keyboard_tb.v
vsim -voptargs=+acc work.ps2_keyboard_tb
add wave -radix hex /ps2_keyboard_tb/dut/*
run 5ms
wave zoom full