`timescale 1ns/1ps

module testbench();

reg clk;
reg rst_n;

always #10 clk = ~clk;

initial begin
    clk = 1'b0;
    rst_n = 1'b1;
    
    repeat (5) @(posedge clk);
    @(posedge clk) rst_n <= 1'b0;
    repeat (5) @(posedge clk);
    @(posedge clk) rst_n <= 1'b1;
end

toplevel #(
    .DATA_INIT_FILE("init_data.mem"),
    .INSTR_INIT_FILE("init_instr_fibo.mem")
) top (
    .SYS_CLK(clk),
    .BTN_RST(!rst_n)
);

endmodule


// init_instr_fibo.mem
// Initializes stack and executes this C code:

//  #include <stdint.h>
//
//  uint32_t* const MEM_BASE = (uint32_t*) 0x00001000ul;
//  
//  void fib_fill() {
//      MEM_BASE[0] = 1;
//      MEM_BASE[1] = 1;
//      for (uint32_t i = 2; i < 1024; i++) 
//      {
//          MEM_BASE[i] = MEM_BASE[i-1] + MEM_BASE[i-2];
//      }
//  }