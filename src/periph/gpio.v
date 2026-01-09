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

module gpio (
    input wire clk,
    input wire ren,
    output reg [7:0] rdata,
    input wire wen,
    input wire [7:0] wdata,
    input wire [7:0] phyin,
    output reg [7:0] phyout
);

reg [7:0] m_phyin;
reg [7:0] s_phyin;

always @(posedge clk) begin
    m_phyin <= phyin;
    s_phyin <= m_phyin;

    if (wen) phyout <= wdata[7:0];
    if (ren) rdata <= s_phyin;
end

endmodule
