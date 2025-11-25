`timescale 1ns / 1ps
/*****************************************************************************
 *  Author: Piotr Kadziela
 *  Description:
 *      Register file for RISC-V core.
 *****************************************************************************/

module regfile (
    input               clk,
    input               rst_n,
    input               clk_enable, // clock enable

    input       [4:0]   r_sel_1,    // number of the first register to read
    input       [4:0]   r_sel_2,    // number of the second register to read
    output      [31:0]  r_data_1,   // data from the first register
    output      [31:0]  r_data_2,   // data from the second register

    input               w_en,       // write enable
    input       [4:0]   w_sel,      // number of the register to write
    input       [31:0]  w_data,     // data to write

    input       [4:0]   dbg_reg_sel, // multiplex debug out
    output      [31:0]  dbg_reg_data // debug data
);

reg [31:0] reg_data [0:31];

assign r_data_1     = reg_data[r_sel_1];
assign r_data_2     = reg_data[r_sel_2];
assign dbg_reg_data = reg_data[dbg_reg_sel];

always @(posedge clk) begin
    if (!rst_n) begin: CLEAR_REG
        integer i;
        for (i = 0; i < 32; i = i + 1) reg_data[i] <= 32'h00000000; // Reset all registers to 0
        $display("reg reset");
    end
    else if (!clk_enable) begin
        // Do nothing when core is halted
    end
    else if (w_en && (w_sel != 5'b00000)) begin  // Don't write to register x0
        reg_data[w_sel] <= w_data;
        $display("reg x%02d <- %0h", w_sel, w_data);
    end
end

endmodule
