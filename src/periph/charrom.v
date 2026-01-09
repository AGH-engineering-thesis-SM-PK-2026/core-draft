`timescale 1ns / 1ps

// TODO
// Szymon Miękina - 17.10.2025

module charrom #(
    FONT = "",
    WIDTH = 4,
    CHARS = 16,
    BITS = 4
) (
    input wire clk,
    input wire readen,
    input wire [BITS - 1:0] csel,
    input wire [2:0] y,
    output reg [WIDTH - 1:0] rowout
);

(* rom_style = "block" *)
reg [WIDTH - 1:0] rom [0:CHARS * 8 - 1];
// trick to simplify logic, requires memory size to be 8 * (2 << N)
// might require padding font bank with zero chars
wire [BITS + 2:0] addr = {y, csel};

reg [WIDTH - 1:0] romout;

always @(posedge clk) begin
    rowout <= romout;
    if (readen) romout <= rom[addr];
end

initial $readmemb(FONT, rom);

endmodule
