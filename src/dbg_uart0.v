/*
 * Author: szym-mie
 * 
 * Simple utility module for sending register contents (32 bits) as raw UART
 * data. TODO: add done outbound signal, for sync purposes.
 */

`include "uart0_tx.v"

module dbg_uart0 #(
    parameter PRESCALER = 625
) (
    input               clk,
    input               wr_en,
    input       [31:0]  wr_data,
    output reg          tx_out
);

wire tx_wr_empty;
reg tx_wr_en = 1'b0;
reg [1:0] bit_cnt = 1'b0;
reg [31:0] tx_wr_data = 1'b0;
reg [31:0] tx_in_data = 1'b0;

uart0_tx #(
    .PRESCALER(PRESCALER)
) tx (
    .clk(clk),
    .wr_en(tx_wr_en),
    .wr_data(tx_wr_data),
    .wr_empty(tx_wr_empty),
    .tx_out(tx_out)
);

always @(posedge clk) begin
    if (wr_en) begin
        bit_cnt <= 1'b0; // reset counter
        tx_wr_data <= wr_data; // load register value
    end else begin
        if (tx_wr_empty) begin
            tx_in_data <= tx_wr_data; // lock uart tx input
            if (bit_cnt < 4) tx_wr_en <= 1'b1; // if still has bytes, send them
            bit_cnt <= bit_cnt + 1'b1; // counter increment
            tx_wr_data <= tx_wr_data >> 8; // shift right by one byte
        end else begin
            tx_wr_en <= 1'b0;
        end
    end
end

endmodule