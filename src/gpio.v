`timescale 1ns / 1ps
/*****************************************************************************
 *  Author: Szymon Miekina
 *  Description:
 *      Basic async GPIO peripheral with 8 output pins.
 *      Base address: 00000400
 *
 *      Register Map:
 *      00000400 -- JC Connector (output pins)
 *                  write only, 8 lowest bits set corresponding output pins
 *
 *****************************************************************************/

module gpio(
    input               clk,

//    input               r_en,   // read enable
//    input       [31:0]  r_addr, // 32-bit address
//    output reg  [31:0]  r_data, // 32-bits of data

    input               w_en,   // write enable
    input       [31:0]  w_addr, // 32-bit address
    input       [31:0]  w_data // 32-bits of data
);

//reg [7:0] out;

always @(posedge clk) begin
//    r_data <= 1'b0; // TODO allow gpio inputs
    if (w_en) begin
//        case (w_addr)
//            8'h00: out <= w_data[7:0];
//        endcase
    end
end

endmodule
