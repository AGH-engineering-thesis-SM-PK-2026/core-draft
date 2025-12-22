`timescale 1ns / 1ps



module spi (
    input wire n_rst,
    input wire clk,
    input wire ren,
    input wire [2:0] raddr,
    output reg [7:0] rdata,
    input wire wen,
    input wire [2:0] waddr,
    input wire [7:0] wdata,
    input wire phymiso,
    output reg phymosi,
    output reg physck
);

reg [7:0] precnt;
reg [3:0] cnt;
reg [7:0] bufout;
reg [7:0] bufin;

always @(posedge clk) begin
    precnt <= precnt + 1'b1;
    if (precnt == 0) begin
        case (cnt)
        4'h0: begin
        
        end
        
        endcase
    end
    
    if (wen) begin
    
    end
    
    if (ren) begin
    
    end

    if (!n_rst) begin
        cnt <= 1'b0;
    end
end

endmodule
