`timescale 1ns / 1ps

module wdconv (
    input wire [1:0] bmul,
    input wire [1:0] boff,
    input wire [31:0] in,
    output reg [31:0] out
);

wire [1:0] hoff = {boff[1],1'b0};

always @(*) begin
    out = 32'b0;
    case (bmul)
    2'b00: out = in[7:0]<<(boff*8);
    2'b01: out = in[15:0]<<(hoff*8);
    2'b10: out = in;
    endcase
end

endmodule
