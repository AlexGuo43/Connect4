# stop any simulation that is currently running
quit -sim

# if simulating with a MIF file, copy it to the working folder. Assumes image.colour.mif
if {[file exists ../object_mem.mif]} {
	file delete object_mem.mif
	file copy ../object_mem.mif .
}

# create the default "work" library
vlib work;

# compile the Verilog source code in the parent folder
vlog ../vga_demo.v ../object_mem.v
# compile the Verilog code of the testbench
vlog *.v
# start the Simulator, including some libraries that may be needed
vsim work.testbench -Lf 220model -Lf altera_mf_ver -Lf verilog
# show waveforms specified in wave.do
do wave.do
# advance the simulation the desired amount of time
run 800 ns
