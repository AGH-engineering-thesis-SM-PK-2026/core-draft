`timescale 1ns / 1ps

// TODO
// Szymon Miękina - 02.11.2025

module unpack1to8 (
    input wire n_rst,
    input wire clk,
    input wire inen,
    input wire [31:0] in,
    input wire outen,
    output wire [3:0] out,
    output reg full,
    output reg empty
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
