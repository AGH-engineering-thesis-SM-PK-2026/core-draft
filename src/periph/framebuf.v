`timescale 1ns / 1ps

// Character Framebuffer
// Does not assume any particular addressing scheme, acts as simple RAM
// Szymon Miękina - 27.10.2025

module framebuf #(
    INIT = "",  // init file for terminal framebuffer
    XBITS = 7,  // bits needed to store column index
    YBITS = 5,  // bits needed to store line index
    COLS = 100, // text columns
    ROWS = 32   // text lines
) (
    input wire                          clk,
    input wire                          readen,     // read enable
    input wire                          writeen,    // write enable
    input wire [XBITS + YBITS - 1:0]    readaddr,   // read address
    input wire [XBITS + YBITS - 1:0]    writeaddr,  // write address
    input wire [7:0]                    charin,     // write character data
    output reg [7:0]                    charout     // read character data
);

// chars will be organized in column-major order
(* ram_style = "block" *)
reg [7:0] ram [0:COLS * ROWS - 1];

// better not read and write at the same time
// at least not to the same block
always @(posedge clk) begin
    if (readen) charout <= ram[readaddr];
    if (writeen) ram[writeaddr] <= charin;
end

initial $readmemh(INIT, ram);

endmodule
