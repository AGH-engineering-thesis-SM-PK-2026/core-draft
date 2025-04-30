/*
 * Author: szym-mie
 * 
 * Simple utility module for sending register contents (32 bits) as raw UART
 * data. TODO: add done outbound signal, for sync purposes.
 */

`include "tx.v"

module reg_print #(
    parameter PRESCALER = 625
) (
    input wire BusClk,
    input wire [31:0] Reg,
    input wire RegWr,
    output reg PhyOut
);

wire TxEmpty;
reg TxSend = 1'b0;
reg [1:0] BCounter = 1'b0;
reg [31:0] TxBuf = 1'b0;
reg [31:0] TxIn = 1'b0;

uart_tx #(
    .PRESCALER = PRESCALER
) UartTx (
    .BusClk = BusClk,
    .BusWr = TxSend,
    .BusData = TxBuf,
    .Empty = TxEmpty,
    .PhyOut = PhyOut
);

always @(posedge BusClk) begin
    if (RegWr) begin
        BCounter <= 1'b0; // reset counter
        TxBuf <= Reg; // load register value
    end else begin
        if (TxEmpty) begin
            TxIn <= TxBuf; // lock uart tx input
            if (BCounter < 4) TxSend <= 1'b1; // if still has bytes, send them
            BCounter <= BCounter + 1'b1; // counter increment
            TxBuf <= TxBuf >> 8; // shift right by one byte
        end else begin
            TxSend <= 1'b0;
        end
    end
end

endmodule