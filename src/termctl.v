`timescale 1ns / 1ps

// TODO
// Szymon Miękina - 03.12.2025

module termctl (
    input wire n_rst,
    input wire cpuclk,
    input wire vgaclk,
    input wire [1:0] dstin,
    input wire [7:0] datain,
    input wire trig,
    output reg busy,
    output reg [6:0] xwrite,
    output reg [4:0] ywrite,
    input wire writeack,
    output reg writereq,
    output wire [7:0] charout
);

wire nonprint;
wire newline;

wire [5:0] fontout;

asciitofont tofont (
    .charin(datain),
    .fontout(fontout),
    .nonprint(nonprint),
    .newline(newline)   
);

// 00 color
assign charout = {2'b00, fontout};

reg [3:0] wrstate;

`define WR_INIT 4'b0000
`define WR_WRITE1 4'b0100
`define WR_WRITEX 4'b0101
`define WR_WRITEY 4'b0110
`define WR_WRITEA 4'b0111
`define WR_WAIT1 4'b1000
`define WR_WAITE 4'b1001
`define WR_NEXT1 4'b1010
`define WR_FINISH 4'b1111

// internal signals
reg u_writereq;
// metastable reg. (1st stage of 2FF synch.)
reg m_writereq;
reg m_writeack;
// synchronized reg. (2nd stage of 2FF synch.)
reg s_writeack;
// also writereq

always @(posedge cpuclk) begin
    case (wrstate)
    `WR_INIT: begin
        busy <= 1'b0;
        if (trig) begin
            busy <= 1'b1;
            wrstate <= `WR_WRITE1;
            case (dstin)
            2'b00: wrstate <= `WR_WRITE1;
            2'b01: wrstate <= `WR_WRITEX;
            2'b10: wrstate <= `WR_WRITEY;
            2'b11: wrstate <= `WR_WRITEA;
            endcase
        end
    end
    `WR_WRITE1: begin
        // write one char
        if (!nonprint) u_writereq <= 1'b1;
        wrstate <= `WR_WAIT1;
    end
    `WR_WRITEX: begin
        // update x
        xwrite <= datain[6:0];
        wrstate <= `WR_WAITE;
    end
    `WR_WRITEY: begin
        // update y
        ywrite <= datain[4:0];
        wrstate <= `WR_WAITE;
    end
    `WR_WRITEA: begin
        // write attribute (not used for now)
        wrstate <= `WR_WAITE;
    end
    `WR_WAIT1: begin
        u_writereq <= 1'b0;
        if (!s_writeack) wrstate <= `WR_NEXT1;
    end
    `WR_WAITE: begin
        wrstate <= `WR_FINISH;
    end
    `WR_NEXT1: begin
        xwrite <= xwrite + 1'b1;
        if (newline || xwrite == 99) begin
            ywrite <= ywrite + 1'b1;
            xwrite <= 1'b0;
        end
        wrstate <= `WR_FINISH;
    end
    `WR_FINISH: begin
        wrstate <= `WR_INIT;
        if (trig) wrstate <= `WR_FINISH;
    end
    endcase
    
    if (!n_rst) begin
        wrstate <= `WR_INIT;
        xwrite <= 1'b0;
        ywrite <= 1'b0;
    end
end


always @(posedge vgaclk) begin
    // writereq synchronizer
    m_writereq <= u_writereq;
    writereq <= m_writereq;
    
    // writeack synchronizer
    m_writeack <= writeack;
    s_writeack <= m_writeack;
end

endmodule
