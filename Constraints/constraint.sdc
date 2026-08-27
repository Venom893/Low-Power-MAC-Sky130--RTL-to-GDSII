current_design mac_core

set clk_name       clk
set clk_period     10.0
set clk_io_pct     0.2

create_clock -name $clk_name -period $clk_period [get_ports clk]

set_false_path -from [get_ports rst_n]

set_input_delay  [expr $clk_period * $clk_io_pct] -clock $clk_name [get_ports {enable start a b}]
set_output_delay [expr $clk_period * $clk_io_pct] -clock $clk_name [get_ports {result done}]
