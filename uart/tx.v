/*
 * Author: szym-mie
 * 
 * Synchronous UART TX driven by bus clk, for now using simplified interface
 * with bus, we will map it to some address, along with data register.
 */

module uart_tx #(
    parameter PRESCALER = 625; // for 6 MHz bus clock
) (
    input wire BusClk,
    input wire BusWr,
    input wire [31:0] BusData,
    output reg Empty,
    output reg PhyOut
);

reg [11:0] PCounter = 1'b0; // prescaler counter
reg [3:0] BCounter = 1'b0; // byte counter
reg [7:0] DataOut = 8'b0; // data out (least significant byte for now)

always @(posedge BusClk) begin
    if (BusWr) begin
        PCounter <= 1'b0;
        BCounter <= 1'b0;
        DataOut <= BusData[7:0];
        Empty <= 1'b0;
    end else begin
        if (PCounter == 0) begin
            PCounter <= 1'b0;
            BCounter <= BCounter < 10 ? BCounter + 1'b1 : 4'd10;
            Empty <= BCounter < 10 ? 1'b0 : 1'b1;
            case (BCounter) begin
                4'd0: begin
                    PhyOut <= 1'b0; // start (low)
                end
                4'd1, 
                4'd2, 
                4'd3, 
                4'd4,
                4'd5, 
                4'd6, 
                4'd7, 
                4'd8: begin 
                    PhyOut <= DataOut[0]; // shift out lsb
                    DataOut <= { 1'b0, DataOut[7:1] };
                end
                4'd9: begin
                    PhyOut <= 1'b1; // stop (high)
                end
            end
        end else begin
            PCounter <= PCounter < PRESCALER ? PCounter + 1'b1 : 1'b0;
        end
    end
end

endmodule
