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
    output reg deven,
    output reg [31:0] devaddr,
    output reg busy
);

wire [31-MASK:0] base = addr[31:MASK];

always @(posedge clk) begin
    deven <= 1'b0;

    if (en) busy <= 1'b0;

    if (en && base == BASE) begin
        devaddr <= addr - OFFS;
        deven <= 1'b1;
        busy <= 1'b1;
    end
    
    if (!n_rst) busy <= 1'b0;
end

endmodule
