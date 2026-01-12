`timescale 1ns / 1ps

// Simple debouncer device
// The sampling period can be controlled using PREBITS, allowing for a freq
// to be divided: /2, /4, /8, ... and so on. The length of the filter is
// controlled by the FILBITS. The filter has:
// - zero impluse response (impulse can be up to FILBITS-1 samples wide)
// - delayed response on low-to-high transition (of FILBITS cycles)
// - infinite response on high-to-low transition (instantenous)
// Szymon Miękina - 06.11.2025

module debounce #(
    PREBITS = 10,
    FILBITS = 4
) (
    input wire  n_rst,
    input wire  clk,
    input wire  in,     // debouncer input
    output reg  out     // debouncer output
);

reg [PREBITS - 1:0] precnt;
reg [FILBITS - 1:0] filter;

always @(posedge clk) begin
    precnt <= precnt + 1'b1;
    out <= &filter;
    // if precounter is full: sample and reset precounter
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
