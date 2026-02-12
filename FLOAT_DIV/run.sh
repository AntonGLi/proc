iverilog -g2012 -s tb *.sv
vvp a.out
gtkwave dump.vcd