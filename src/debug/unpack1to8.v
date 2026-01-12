`timescale 1ns / 1ps

// Unpack 32 bits into 8 4-bit nibbles
// A specialised shift register. 32 bits are clocked in using 'inen', and then
// external logic can fetch 8 4-bit parts of that value. Useful for encoding
// 32-bit words as hexadecimal string. The 'full' condition is only high when
// the data was clocked in and the first nibble is outputed. Using 'outen' will
// lower the flag. The 'empty' condition arises when the buffer is truly empty.
// The module will output '0000' when the buffer is empty.
// Szymon Miękina - 02.11.2025

module unpack1to8 (
    input wire          n_rst,
    input wire          clk,
    input wire          inen,   // input enable
    input wire [31:0]   in,     // 32-bit value input
    input wire          outen,  // shift-out to next value
    output wire [3:0]   out,    // 4-bit value output
    output reg          full,   // is buffer full (new value clocked in)
    output reg          empty   // is buffer empty
);

reg [31:0] data;
reg [3:0] cnt;

assign out = data[31:28];

always @(posedge clk) begin
    if (outen) begin
        cnt <= cnt + 1'b1;
        data <= {data[27:0], 4'b0000};    
    end
 
    if (cnt == 1) full <= 1'b0;
    if (cnt == 8) empty <= 1'b1;
    
    if (inen) begin
        cnt <= 1'b0;
        data <= in;
        full <= 1'b1;
        empty <= 1'b0;
    end
    
    if (!n_rst) begin
        full <= 1'b0;
        empty <= 1'b1;
    end
end

endmodule
