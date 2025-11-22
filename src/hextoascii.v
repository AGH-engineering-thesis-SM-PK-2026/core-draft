`timescale 1ns / 1ps

// TODO
// Szymon Miękina - 04.11.2025

module hextoascii (
    input wire [3:0] hexin,
    output reg [7:0] charout
);

always @(*) begin
    case (hexin)
    4'h0, 4'h1, 4'h2, 4'h3, 
    4'h4, 4'h5, 4'h6, 4'h7, 
    4'h8, 4'h9: 
        charout = {4'h3, hexin};
    4'ha, 4'hb, 4'hc, 4'hd, 
    4'he, 4'hf: 
        charout = hexin + 8'h37;
    endcase
end

endmodule
