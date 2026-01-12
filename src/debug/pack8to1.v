`timescale 1ns / 1ps

// Pack 8 4-bit nibbles into a 32-bit word
// A specialised shift registers: 8 4-bit can be shifted in one-by-one
// to obtain 32-bit value. Useful for assembling words from UART frames.
// The 'full' condition is raised when the 32-bit word is complete, while
// 'empty' is only high when the buffer is empty.
// Szymon Miękina - 24.11.2025

module pack8to1 (
    input wire          n_rst,
    input wire          clk,
    input wire          inen,   // input enable
    input wire [3:0]    in,     // 4-bit input
    input wire          outen,  // confirm the output was read
    output reg [31:0]   out,    // 32-bit assembled output
    output reg          full,   // output is ready
    output reg          empty   // buffer is empty
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
