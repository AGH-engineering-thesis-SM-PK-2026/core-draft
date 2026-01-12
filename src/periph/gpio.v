`timescale 1ns / 1ps

// GPIO peripheral
// The peripheral maps 1 register:
// A (0) - write to set output states of 8 output pins,
//         reading will capture the state of 8 input pins
// Szymon Miękina - 01.12.2025

module gpio (
    input wire          clk,
    input wire          ren,    // read enable
    output reg [7:0]    rdata,  // read data
    input wire          wen,    // write enable
    input wire [7:0]    wdata,  // write data
    input wire [7:0]    phyin,  // physical GPIO input pins
    output reg [7:0]    phyout  // physical GPIO output pins
);

// physical input pins synchronisation
reg [7:0] m_phyin;
reg [7:0] s_phyin;

always @(posedge clk) begin
    m_phyin <= phyin;
    s_phyin <= m_phyin;

    if (wen) phyout <= wdata[7:0];
    if (ren) rdata <= s_phyin;
end

endmodule
