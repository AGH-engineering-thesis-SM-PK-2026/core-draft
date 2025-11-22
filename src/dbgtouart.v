`timescale 1ns / 1ps

// TODO
// Szymon Miękina - 04.11.2025

module dbgtouart (
    input wire n_rst,
    input wire dbgclk,
    input wire trig,
    input wire uartbusy,
    output reg busy,
    output reg [4:0] dbgsel,
    output reg dbgreaden,
    input wire [31:0] dbgout,
    output wire [7:0] charout,
    output reg uarttxen
);

wire full;
reg empty1;
wire empty8;

reg inen;
reg outen;

wire [3:0] hexout;

wire [7:0] hexchar;
reg [7:0] sigchar;

reg srcsel;

assign charout = srcsel ? sigchar : hexchar;

hextoascii toascii (
    .hexin(hexout),
    .charout(hexchar)
);

unpack1to8 unpack (
    .n_rst(n_rst),
    .clk(dbgclk),
    .inen(inen),
    .in(dbgout),
    .outen(outen),
    .out(hexout),
    .full(full),
    .empty(empty8)
);

parameter DBG_INIT = 4'b0000;
parameter DBG_READ8A = 4'b0001;
parameter DBG_READ8B = 4'b0010;
parameter DBG_WAIT8 = 4'b0011;
parameter DBG_PSTART = 4'b0100;
parameter DBG_FCOMMA = 4'b0101;
parameter DBG_REGSEL = 4'b0110;
parameter DBG_ENDOFP = 4'b0111;
parameter DBG_TXINIT = 4'b1000;
parameter DBG_TXSEND1 = 4'b1001;
parameter DBG_TXSEND8 = 4'b1010;
parameter DBG_TXPOLLA = 4'b1100;
parameter DBG_TXPOLLB = 4'b1101;
parameter DBG_WAIT = 4'b1111;

reg [3:0] dbgstate;
reg packetend;

always @(posedge dbgclk) begin
    case (dbgstate)
    DBG_INIT: begin
        if (trig && !busy) begin
            busy <= 1'b1;
            dbgsel <= 5'b00000;
            dbgstate <= DBG_PSTART;
            packetend <= 1'b0;
        end
    end
    DBG_PSTART: begin
        // packet start 'P'
        sigchar <= "P";
        empty1 <= 1'b0;
        srcsel <= 1'b1;
        dbgstate <= DBG_TXINIT;
    end
    DBG_FCOMMA: begin
        // end of field ','
        sigchar <= ",";
        empty1 <= 1'b0;
        srcsel <= 1'b1;
        dbgstate <= DBG_TXINIT;     
    end
    DBG_REGSEL: begin
        // start switch to next register
        dbgsel <= dbgsel + 1'b1;
        srcsel <= 1'b0;
        if (dbgsel == 5'b11111) dbgstate <= DBG_ENDOFP;
        else dbgstate <= DBG_READ8A;
    end
    DBG_ENDOFP: begin
        // end of packet '\n'
        sigchar <= "\n";
        empty1 <= 1'b0;
        srcsel <= 1'b1;
        packetend <= 1'b1;
        dbgstate <= DBG_TXINIT;
    end
    DBG_READ8A: begin
        // read dbg reg
        dbgreaden <= 1'b1;
        dbgstate <= DBG_READ8B;
    end
    DBG_READ8B: begin
        // pass into 8to1unpack
        dbgreaden <= 1'b0;
        inen <= 1'b1;
        dbgstate <= DBG_WAIT8;
    end
    DBG_WAIT8: begin
        // wait for settle
        inen <= 1'b0;
        dbgstate <= DBG_TXINIT;
    end
    DBG_TXINIT: begin
        if (srcsel) begin
            if (!empty1) begin
                uarttxen <= 1'b1;
                dbgstate <= DBG_TXSEND1;            
            end else dbgstate <= DBG_REGSEL;
        end else begin
            // if empty select next register
            if (!empty8) begin
                uarttxen <= 1'b1;
                dbgstate <= DBG_TXSEND8;
            end else dbgstate <= DBG_FCOMMA;
        end
    end
    DBG_TXSEND1: begin
        // sending 1 byte (source: sigchar)
        uarttxen <= 1'b0;
        empty1 <= 1'b1;
        dbgstate <= DBG_TXPOLLB;
    end
    DBG_TXSEND8: begin
        // sending 8 bytes (source: hexchar)
        uarttxen <= 1'b0;
        dbgstate <= DBG_TXPOLLA;
    end
    DBG_TXPOLLA: begin
        // clock out data from unpack
        outen <= 1'b1;
        dbgstate <= DBG_TXPOLLB;
    end
    DBG_TXPOLLB: begin
        // poll for uart busy line
        outen <= 1'b0;
        if (!uartbusy) dbgstate <= packetend ? DBG_WAIT : DBG_TXINIT;
    end
    DBG_WAIT: begin
        // wait for trigger release
        busy <= 1'b0;
        if (!trig) dbgstate <= DBG_INIT;
    end
    default: begin
        // invalid state
        dbgstate <= DBG_INIT;
    end
    endcase

    if (!n_rst) begin
        dbgstate <= DBG_INIT;
        busy <= 1'b0;
        dbgreaden <= 1'b0;
        inen <= 1'b0;
        outen <= 1'b0;
        srcsel <= 1'b0;
        empty1 <= 1'b1;
        packetend <= 1'b0;
        uarttxen <= 1'b0;
    end
end

endmodule
