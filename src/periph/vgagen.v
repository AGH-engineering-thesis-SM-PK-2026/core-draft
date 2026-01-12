`timescale 1ns / 1ps

// VGA signal generator + coordinate generator
// This module is used to generate video synchronisation signals VSYNC, HSYNC.
// Other modules are also synchronised with this logic via the screen coords.
// Szymon Miękina - 17.10.2025

// 800x600 60fps
module vgagen (
    input wire          n_rst,
    input wire          clk,
    output reg [10:0]   x,      // screen x component
    output reg [9:0]    y,      // screen y component
    output reg          hsync,  // horizontal sync signal output
    output reg          vsync,  // vertical sync signal output
    output wire         dpyen   // is in active region
);

parameter HFRONT = 807;
parameter HSYNCS = HFRONT + 40;
parameter HSYNCE = HSYNCS + 128;
parameter HEND = 1055;

parameter VFRONT = 599;
parameter VSYNCS = VFRONT + 1;
parameter VSYNCE = VSYNCS + 4;
parameter VEND = 627;

reg harea; // area is an active drawing region 800x600
reg varea;

assign dpyen = harea && varea; // display enable - can output
// otherwise the video signals should stay at 'fully black' - it is up to
// external logic to ensure this happens.

always @(posedge clk) begin
    if (x == HEND) begin
        x <= 0;
        y <= (y == VEND) ? 0 : y + 1;
    end else x <= x + 1;
    
    if (x == HSYNCS) hsync <= 1'b0;
    if (x == HSYNCE) hsync <= 1'b1;
    if (y == VSYNCS) vsync <= 1'b0;
    if (y == VSYNCE) vsync <= 1'b1;
    if (x == HFRONT) harea <= 1'b0;
    if (y == VFRONT) varea <= 1'b0;
    if (x == 8) harea <= 1'b1;
    if (y == 0) varea <= 1'b1;

    if (!n_rst) begin
        x <= 1'b0;
        y <= 1'b0;
        hsync <= 1'b1;
        vsync <= 1'b1;
        harea <= 1'b1;
        varea <= 1'b1;
    end
end

endmodule
