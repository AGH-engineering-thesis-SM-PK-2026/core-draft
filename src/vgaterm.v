`timescale 1ns / 1ps

// TODO
// Szymon Miękina - 27.10.2025

module vgaterm (
    input wire clk,
    input wire [10:0] xread,
    input wire [9:0] yread,
    input wire [6:0] xwrite,
    input wire [4:0] ywrite,
    input wire [7:0] charin,
    input wire writereq, // queue for writing
    output reg writeack, // acknowledge request / busy writing
    output reg out
);

// triggers every 8th x change in the middle of char drawing
wire readen = xread[2];
// double-buffered row output for glitchless display
reg [7:0] row1;
reg [7:0] row2;
wire [7:0] rowout;
// current char from framebuffer
wire [7:0] char;

charrom #(
    .FONT("font_ascii.mem"),
    .WIDTH(8),
    .CHARS(64),
    .BITS(6)
) fontutilrom (
    .clk(clk),
    .readen(readen),
    .csel(char[5:0]),
    .y(yread[3:1]),
    .rowout(rowout)
);

// display logic
always @(*) begin
    case (xread[3:0])
        4'b0000: out = row1[7];
        4'b0001: out = row1[6];
        4'b0010: out = row1[5];
        4'b0011: out = row1[4];
        4'b0100: out = row1[3];
        4'b0101: out = row1[2];
        4'b0110: out = row1[1];
        4'b0111: out = row1[0];
        4'b1000: out = row2[7];
        4'b1001: out = row2[6];
        4'b1010: out = row2[5];
        4'b1011: out = row2[4];
        4'b1100: out = row2[3];
        4'b1101: out = row2[2];
        4'b1110: out = row2[1];
        4'b1111: out = row2[0];
    endcase
end

// a neat trick to simplify logic
// enabled by having 32 rows and column-major order
wire [11:0] readaddr = {xread[9:3], yread[8:4]};

reg writeen;
reg [11:0] writeaddr;
reg [7:0] writechar;

// framebuffer output is read after 2 ticks of clk
always @(posedge clk) begin
    if (xread[3:1] == 3'b011) row2 <= rowout;
    if (xread[3:1] == 3'b111) row1 <= rowout;
    
    // we need to enqueue data for next write cycle
    if (writereq && !writeack) begin
        writeack <= 1'b1;
        writeaddr <= {xwrite, ywrite};
        writechar <= charin;
    end
    
    // at this moment read cycle will end permiting one write
    if (xread[2:0] == 3'b000 && writeack) writeen <= 1'b1;
    
    // after write commenced and 2 ticks since write begin
    if (xread[2:0] == 3'b010 && writeen) begin
        writeack <= 1'b0; // write done
        writeen <= 1'b0;
    end
end

framebuf #(
    .INIT("init_term.mem"),
    .XBITS(7), 
    .YBITS(5),
    .COLS(100), 
    .ROWS(32)
) fbuf (
    .clk(clk),
    .readen(readen),
    .readaddr(readaddr),
    .writeen(writeen),
    .writeaddr(writeaddr),
    .charin(writechar),
    .charout(char)
);

endmodule
