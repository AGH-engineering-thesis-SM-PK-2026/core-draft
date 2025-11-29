`timescale 1ns / 1ps

// TODO
// Szymon Miękina - 23.11.2025

module busdev #(
    BASE = 32'h00000000,
    OFFS = 32'h00000000,
    MASK = 4
) (
    input wire n_rst,
    input wire clk,
    input wire en,
    input wire [31:0] addr,
    output wire deven,
    output wire [MASK-1:0] devaddr,
    output wire busy
);

wire [31-MASK:0] base = addr[31:MASK];

assign deven = base == BASE ? en : 1'b0;
assign devaddr = addr[MASK-1:0];
assign busy = base == BASE;

// previously I've imagined a synchronous circuit - this turned out
// unnecessary, the path is very short here with little logic in
// between.
//always @(posedge clk) begin
//    deven <= 1'b0;
//
//    if (en) busy <= 1'b0;
//
//    if (en && base == BASE) begin
//        devaddr <= addr[MASK-1:0];
//        deven <= 1'b1;
//        busy <= 1'b1;
//    end
//    
//    if (!n_rst) busy <= 1'b0;
//end

endmodule
