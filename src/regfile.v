`timescale 1ns / 1ps
/*****************************************************************************
 *  Author: Piotr Kadziela
 *  Description:
 *      Register file for RISC-V core.
 *****************************************************************************/

module regfile (
    input               clk,
    input               rst_n,

    input       [4:0]   r_sel_1,    // number of the first register to read
    input       [4:0]   r_sel_2,    // number of the second register to read
    output      [31:0]  r_data_1,   // data from the first register
    output      [31:0]  r_data_2,   // data from the second register

    input               w_en,       // write enable
    input       [4:0]   w_sel,      // number of the register to write
    input       [31:0]  w_data,     // data to write

    input       [4:0]   dbg_reg_sel, // multiplex debug out
    output      [31:0]  dbg_reg_data,// debug data

    input       [7:0]   io_in,       // IO input r31[15:8]
    output      [7:0]   io_out       // IO output r31[7:0]
);

reg [31:0] reg_data [0:31];

reg [7:0] io_in_latch;
reg [7:0] io_out_latch;

assign r_data_1     = reg_data[r_sel_1];
assign r_data_2     = reg_data[r_sel_2];
assign dbg_reg_data = reg_data[dbg_reg_sel];
assign io_out       = io_out_latch;

always @(posedge clk) begin
    if (!rst_n) begin
        if (w_en && (w_sel != 5'b00000)) begin  // Don't write to register x0
            reg_data[w_sel] <= w_data;
        end
        // IO input synchronizer
        reg_data[31][15:8] <= io_in_latch;
        io_in_latch <= io_in;
        // IO output driver
        io_out_latch <= reg_data[31][7:0];
    end else begin: CLEAR_REG
        integer i;
        for (i = 0; i < 32; i = i + 1) reg_data[i] <= 32'h00000000; // Reset all registers to 0
    end
end

initial begin: CLEAR_REG_INIT
    integer i;
    for (i = 0; i < 32; i = i + 1) reg_data[i] <= 32'h00000000; // Reset all registers to 0
end

endmodule
