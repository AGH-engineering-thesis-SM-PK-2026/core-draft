`timescale 1ns / 1ps

module wbmul (
    input wire [1:0] bmul,
    input wire [1:0] boff,
    output reg [3:0] strb
);

wire [1:0] hoff = {boff[1],1'b0};

always @(*) begin
    strb = 4'b0000;
    case (bmul)
    2'b00: strb = 4'b0001<<boff;
    2'b01: strb = 4'b0011<<hoff;
    2'b10: strb = 4'b1111;
    endcase
end

endmodule
