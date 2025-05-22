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

    output      [(32*32)-1:0] dbg_reg_data  // debug data
);

assign r_data_1 = reg_data[r_sel_1];
assign r_data_2 = reg_data[r_sel_2];

reg [31:0] reg_data [0:31];
assign dbg_reg_data = { reg_data[31], reg_data[30], reg_data[29], reg_data[28], reg_data[27], reg_data[26], reg_data[25], reg_data[24],
                        reg_data[23], reg_data[22], reg_data[21], reg_data[20], reg_data[19], reg_data[18], reg_data[17], reg_data[16],
                        reg_data[15], reg_data[14], reg_data[13], reg_data[12], reg_data[11], reg_data[10], reg_data[9],  reg_data[8],
                        reg_data[7],  reg_data[6],  reg_data[5],  reg_data[4],  reg_data[3],  reg_data[2],  reg_data[1]};

always @(negedge rst_n) begin: CLEAR_REG
    integer i;
    for (i = 0; i < 32; i = i + 1) reg_data[i] <= 32'h00000000; // Reset all registers to 0
end

always @(posedge clk) begin
    if(!rst_n) begin
        if (w_en && (w_sel != 5'b00000)) begin  // Don't write to register x0
            reg_data[w_sel] <= w_data;
        end
    end
end


initial begin: CLEAR_REG_INIT
    integer i;
    for (i = 0; i < 32; i = i + 1) reg_data[i] <= 32'h00000000; // Reset all registers to 0
end

endmodule
