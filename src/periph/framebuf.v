`timescale 1ns / 1ps

// TODO
// Szymon Miękina - 27.10.2025

module framebuf #(
    INIT = "",
    XBITS = 7, 
    YBITS = 5,
    COLS = 100, 
    ROWS = 32
) (
    input wire clk,
    input wire readen,
    input wire writeen,
    input wire [XBITS + YBITS - 1:0] readaddr,
    input wire [XBITS + YBITS - 1:0] writeaddr,
    input wire [7:0] charin,
    output reg [7:0] charout
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
