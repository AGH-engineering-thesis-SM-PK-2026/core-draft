`timescale 1ns / 1ps

// VGA Terminal Peripheral
// The peripheral maps 4 registers:
// OUT  (0) - write to display a character at the position of the cursor
// X    (1) - write to change cursors' X coordinate
// Y    (2) - write to change cursors' Y coordinate
// ATTR (3) - set character attributes (currently no-op)
// Szymon Miękina - 04.12.2025

module term (
    input wire          n_rst,
    input wire          cpuclk, // CPU side clock signal
    input wire          vgaclk, // VGA side clock signal
    input wire [1:0]    addrin, // register write address
    input wire [7:0]    datain, // register write data
    input wire          inen,   // write enable
    output wire         busy,   // is busy writing to framebuffer
    output wire         vidlm,  // video luminance signal
    output wire         vidhs,  // video hsync
    output wire         vidvs   // video vsync
);

wire [7:0] charout;
wire [10:0] xread;
wire [9:0] yread;
wire [6:0] xwrite;
wire [4:0] ywrite;
wire writereq;
wire writeack;

termctl ctl (
    .n_rst(n_rst),
    .cpuclk(cpuclk),
    .vgaclk(vgaclk),
    .dstin(addrin),
    .datain(datain),
    .trig(inen),
    .busy(busy),
    .xwrite(xwrite),
    .ywrite(ywrite),
    .writeack(writeack),
    .writereq(writereq),
    .charout(charout)
);

wire vidout;
wire dpyen;

assign vidlm = vidout && dpyen;

vgaterm term (
    .clk(vgaclk),
    .xread(xread),
    .yread(yread),
    .xwrite(xwrite),
    .ywrite(ywrite),
    .charin(charout),
    .writereq(writereq), // queue for writing
    .writeack(writeack), // acknowledge request / busy writing
    .out(vidout)
);

vgagen gen (
    .n_rst(n_rst),
    .clk(vgaclk),
    .x(xread),
    .y(yread),
    .hsync(vidhs),
    .vsync(vidvs),
    .dpyen(dpyen)
);

endmodule