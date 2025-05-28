`timescale 1ns/1ps

module testbench(
);

wire [3:0] state;
reg clk = 0;

always #100 clk = ~clk;

toplevel top(
    .GLOBAL_CLK_IN(clk),
    .jb_state(state)
);

    
endmodule