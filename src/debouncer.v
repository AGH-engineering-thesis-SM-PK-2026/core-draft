`timescale 1ns / 1ps

// TODO
// Szymon Miękina - 06.11.2025

module debounce #(
    PREBITS = 10,
    FILBITS = 4
) (
    input wire n_rst,
    input wire clk,
    input wire in,
    output reg out
);

reg [PREBITS - 1:0] precnt;
reg [FILBITS - 1:0] filter;

always @(posedge clk) begin
    precnt <= precnt + 1'b1;
    out <= &filter;
    if (&precnt) begin 
        filter <= {filter[FILBITS - 2:0], in};
        precnt <= 1'b0;
    end
    
    if (!n_rst) begin
        filter <= 1'b0;
        out <= 1'b0;
    end
end

endmodule
