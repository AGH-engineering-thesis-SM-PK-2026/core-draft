`timescale 1ns / 1ps

// TODO
// Szymon Miękina - 24.11.2025

module pack8to1 (
    input wire n_rst,
    input wire clk,
    input wire inen,
    input wire [3:0] in,
    input wire outen,
    output reg [31:0] out,
    output reg full,
    output reg empty
);

reg [3:0] cnt;

always @(posedge clk) begin
    if (inen && !full) begin
        cnt <= cnt + 1'b1;
        out <= {out[27:0], in};
        if (cnt == 7) full <= 1'b1;
    end

    if (cnt == 1) empty <= 1'b0;

    if (!n_rst || outen) begin
        cnt <= 1'b0;
        full <= 1'b0;
        empty <= 1'b1;
    end
end

endmodule
