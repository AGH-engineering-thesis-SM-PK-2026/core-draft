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
    //.INSTR_INIT_FILE("init_instr.mem")
    .INSTR_INIT_FILE("init_instr_fibo.mem")
) top (
    .GLOBAL_CLK_IN(clk),
    .GLOBAL_RST_N(rst_n)
);


// .global _boot
// .text
// 
// _boot:                       /* x0   =   0     */
//      addi x1 , x0,  100      /* x1   =   100   */
//      addi x2 , x1,  250      /* x2   =   350   */
//      addi x3 , x2, -100      /* x3   =   250   */
//      addi x4 , x3, -2000     /* x4   =   -1750 */
//      addi x5 , x4,  1000     /* x5   =   -750  */
//      add  x6 , x5, x4        /* x6   =   -2500 */
// 
//      sw 	 x6 , 0x0010(x0)    /* DATA_MEM[0x0010] = -2500 */
//      lw 	 x7 , 0x0010(x0)    /* x7   = -2500 */
//      addi x7 , x7, 5		    /* x7   = -2495 */

//      instr_data.mem:
//      06400093
//      0fa08113
//      f9c10193
//      83018213
//      3e820293
//      00428333
//      00602823
//      01002383
//      00538393

endmodule