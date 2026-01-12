`timescale 1ns / 1ps

// ASCII to font glyph index converter
// Szymon Miękina - 03.12.2025

module asciitofont (
    input wire [7:0]    charin,     // ASCII input
    output reg [5:0]    fontout,    // font index output
    output reg          nonprint,   // is character not printable 0x00-0x1f
    output reg          newline     // is character a newline '\n'
);

// careful, this module is asynchronous and thus glitches can propagate 
// to signals 'nonprint', 'newline'
always @(*) begin
    // a little cheat of a remapping
    // 0x00 -> 0x00, 0x20 -> 0x00, 0x40 -> 0x20, 0x60 -> 0x20
    fontout = {charin[6], charin[4:0]};
    nonprint = charin[7:5] == 3'b000;
    newline = charin[6:0] == {3'b000, 4'ha};
end

endmodule
