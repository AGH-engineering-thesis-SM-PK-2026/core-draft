/*
 * Author: szym-mie
 * 
 * Synchronous UART TX driven by bus clk, for now using simplified interface
 * with bus, we will map it to some address, along with data register.
 */

module uart0_tx #(
    parameter PRESCALER = 625 // 9600 bps for 6 MHz bus clock
) (
    input               clk,
    input               wr_en,
    input       [31:0]  wr_data,
    output reg          wr_empty,
    output reg          tx_out
);

reg [11:0]  pre_cnt = 1'b0; // prescaler counter
reg [3:0]   bit_cnt = 1'b0; // bit counter
reg [7:0]   tx_data = 8'b0; // data out (least significant byte for now)

always @(posedge clk) begin
    if (wr_en) begin
        pre_cnt <= 1'b0;
        bit_cnt <= 1'b0;
        tx_data <= wr_data[7:0];
        wr_empty <= 1'b0;
    end else begin
        if (pre_cnt == 0) begin
            pre_cnt <= 1'b0;
            bit_cnt <= bit_cnt < 10 ? bit_cnt + 1'b1 : 4'd10;
            wr_empty <= bit_cnt < 10 ? 1'b0 : 1'b1;
            case (bit_cnt)
                4'd0: begin
                    tx_out <= 1'b0; // start (low)
                end
                4'd1, 
                4'd2, 
                4'd3, 
                4'd4,
                4'd5, 
                4'd6, 
                4'd7, 
                4'd8: begin 
                    tx_out <= tx_data[0]; // shift out lsb
                    tx_data <= { 1'b0, tx_data[7:1] };
                end
                4'd9: begin
                    tx_out <= 1'b1; // stop (high)
                end
            endcase
        end else begin
            pre_cnt <= pre_cnt < PRESCALER ? pre_cnt + 1'b1 : 1'b0;
        end
    end
end

endmodule