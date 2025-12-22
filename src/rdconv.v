`timescale 1ns / 1ps

module rdconv (
    input wire [1:0] bmul,
    input wire [1:0] aoff,
    input wire [31:0] in,
    output reg [31:0] out
);

wire [1:0] boff = aoff ^ 2'b11;
wire [1:0] hoff = {aoff[1] ^ 1'b1,1'b0};

always @(*) begin
    out = 32'b0;
    case (bmul)
    2'b00: out = {24'b0,in[boff*8+:8]};
    2'b01: out = {16'b0,in[hoff*8+:16]};
    2'b10: out = in;
    endcase
end

endmodule
