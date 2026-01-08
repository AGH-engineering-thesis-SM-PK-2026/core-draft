`timescale 1ns / 1ps
/*****************************************************************************
 *  Author: Piotr Kadziela
 *  Description:
 *      Register file for RISC-V core.
 *      Resetting the register file causes all the registers to be zeroed 
 *    sequentially. After that, the 'ready' signal goes high.
 *****************************************************************************/

module regfile (
    input               clk,
    input               rst_n,
    output              rst_ready,    // high when reset is finished (after zeroing all registers)

    input       [4:0]   r_sel_1,      // number of the first register to read
    input       [4:0]   r_sel_2,      // number of the second register to read
    output      [31:0]  r_data_1,     // data from the first register
    output      [31:0]  r_data_2,     // data from the second register

    input               w_en,         // write enable
    input       [4:0]   w_sel,        // number of the register to write
    input       [31:0]  w_data,       // data to write

    input       [4:0]   dbg_reg_sel,  // multiplex debug out
    output      [31:0]  dbg_reg_data  // debug data
);

reg [31:0] reg_data [0:31];           // 32 registers of 32 bits each
reg [4:0] rst_cnt;                    // reset counter needed for sequential reset

assign r_data_1     = reg_data[r_sel_1];
assign r_data_2     = reg_data[r_sel_2];
assign dbg_reg_data = reg_data[dbg_reg_sel];
assign rst_ready    = (rst_cnt == 5'b00000);   // ready when reset counter overflows

always @(posedge clk) begin
    if (!rst_n) begin           // Start reset process
        rst_cnt <= 5'b00001;
        reg_data[0] <= 32'b0;   // x0 is always zero, but we still need to set it during reset
    end 
    else if (!rst_ready) begin  // During reset, zero registers sequentially
        reg_data[rst_cnt] <= 32'b0;
        rst_cnt <= rst_cnt + 1;
    end 
    else if (w_en && w_sel != 5'b00000) begin  // Normal operation: write to register (but x0 is always zero)
        reg_data[w_sel] <= w_data;
    end
end

endmodule
