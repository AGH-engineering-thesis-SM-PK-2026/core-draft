`timescale 1ns / 1ps

// TODO
// Szymon Miękina - 04.12.2025

module term (
    input wire n_rst,
    input wire cpuclk,
    input wire vgaclk,
    input wire [1:0] addrin,
    input wire [7:0] datain,
    input wire inen,
    output wire busy,
    output wire vidlm,
    output wire vidhs,
    output wire vidvs
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