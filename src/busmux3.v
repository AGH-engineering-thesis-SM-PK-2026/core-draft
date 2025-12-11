`timescale 1ns / 1ps

// TODO
// Szymon Miękina - 05.12.2025

module busmux3 (
    input wire busy1,
    input wire busy2,
    input wire busy3,
    input wire [31:0] src1,
    input wire [31:0] src2,
    input wire [31:0] src3,
    output reg [31:0] out
);

always @(*) begin
    out <= 32'h00000000;
    if (busy1) out <= src1;
    if (busy2) out <= src2;
    if (busy3) out <= src3;
end

endmodule
