`timescale 1ns / 1ps

// Character ROM
// Stores visual representation of font glyphs as read-only memory
// Each character can be selected by index and then the row of the
// character (characters are drawn row-by-row).
// Szymon Miękina - 17.10.2025

module charrom #(
    FONT = "",  // font file
    WIDTH = 4,  // character width in pixels
    CHARS = 16, // character count
    BITS = 4    // bits needed to store character index
) (
    input wire                  clk,
    input wire                  readen, // read enable
    input wire [BITS - 1:0]     csel,   // character select (glyph index)
    input wire [2:0]            y,      // row select
    output reg [WIDTH - 1:0]    rowout  // row output
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
