`timescale 1ns / 1ps

module dbgsel (
    input wire selregmem,
    input wire dbgreaden,
    input wire [31:0] regin,
    input wire [31:0] datain,
    output wire [31:0] dbgout
);

assign dbgout = selregmem ? datain : regin;

endmodule
