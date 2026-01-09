`timescale 1ns / 1ps

// TODO
// Szymon Miękina - 23.11.2025

module busdev #(
    BASE = 32'h00000000,
    OFFS = 32'h00000000,
    MASK = 4
) (
    input               en,         // enable signal from bus
    input       [31:0]  addr,       // address from bus
    output              deven,      // device enable signal
    output  [MASK-1:0]  devaddr,    // address within device
    output              sel         // high when device is selected
);

wire [31-MASK:0] base = addr[31:MASK];

assign deven    = base == BASE ? en : 1'b0;
assign devaddr  = addr[MASK-1:0];
assign sel      = base == BASE;

endmodule
