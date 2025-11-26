`timescale 1ns / 1ps

// TODO
// Szymon Miękina - 24.11.2025

// H - halt
// Z - ztart
// S - step cpu
// R - reset cpu
// P - program, first word is prog size, rest is prog data
// V - data/prog view page index

module uarttoctl #(
    parameter DVPBITS = 8, // data view offset bits
    parameter PVPBITS = 8 // prog view offset bits
) (
    input wire n_rst,
    input wire clk,
    input wire [7:0] charin,
    input wire uartdone,
    input wire acklast,
    output reg cpuhalt,
    output reg cpustart,
    output reg cpustep,
    output reg cpurst,
    output wire dbg,
    output reg [DVPBITS-1:0] dvpage,
    output reg [PVPBITS-1:0] pvpage,
    output reg progen,
    output reg [19:0] progaddr,
    output wire [31:0] progdata
);

reg busy;
reg readinit; // 1 when read UART data
reg readdone; // 1 when read UART data
reg [7:0] data;
wire [3:0] hexin;

wire empty8;
wire full8;
reg packinen;
reg packouten;

assign dbg = progen;
//assign dbg = empty8;
//assign dbg = packinen;

asciitohex tohex (
    .charin(data),
    .hexout(hexin),
    .nothex()
);

pack8to1 pack (
    .n_rst(n_rst),
    .clk(clk),
    .inen(packinen),
    .in(hexin),
    .outen(packouten),
    .out(progdata),
    .full(full8),
    .empty(empty8)
);

// only these are necessary for argument parsing
`define CMD_PROG 2'b01
`define CMD_VIEW 2'b10
`define CMD_NONE 2'b00

`define CTL_STARTP 5'b00000 // command name
`define CTL_READ0A 5'b00001 // push to arg0
`define CTL_READ0B 5'b00010 // reflect about arg0
`define CTL_READ0C 5'b00011 // arg0 comma ','
`define CTL_READ1A 5'b00100 // push to arg0
`define CTL_READ1B 5'b00101 // reflect about arg1
`define CTL_READPA 5'b00110 // read body
`define CTL_READPB 5'b00111 // read body
`define CTL_READPF 5'b01000 // read body
`define CTL_PCOMMA 5'b01001 // prog comma ','
`define CTL_STARTB 5'b01010 // start of body '['
`define CTL_ENDOFH 5'b01011 // end-of-halt '\n'
`define CTL_ENDOFZ 5'b01100 // end-of-ztart '\n'
`define CTL_ENDOFS 5'b01101 // end-of-step '\n'
`define CTL_ENDOFR 5'b01110 // end-of-reset '\n'
`define CTL_ENDOFV 5'b01111 // end-of-view '\n'
`define CTL_BADCMD 5'b10000 // bad command

reg [4:0] ctlstate;

// arg0: P: prog size | V: data page ndx
// arg1: V: prog page ndx
reg [1:0] cmdid;
reg [15:0] arg0;
reg [15:0] arg1;

reg inbound;

always @(posedge clk) begin
    if (acklast) begin
        cpuhalt <= 1'b0;
        cpustart <= 1'b0;
        cpustep <= 1'b0;
        cpurst <= 1'b0;
    end

    if (!uartdone) readinit <= 1'b0;

    inbound <= readinit && !readdone;
    readdone <= readinit;

    if (uartdone && !readinit) begin
        data <= charin;
        readinit <= 1'b1;
    end
    
    case (ctlstate)
    `CTL_STARTP: begin
        if (inbound) begin
            cmdid <= `CMD_NONE;
            arg0 <= 16'h0000;
            arg1 <= 16'h0000;
            
            case (data)
            "H": ctlstate <= `CTL_ENDOFH;
            "Z": ctlstate <= `CTL_ENDOFZ;
            "S": ctlstate <= `CTL_ENDOFS;
            "R": ctlstate <= `CTL_ENDOFR;
            "P": begin
                cmdid <= `CMD_PROG;
                cpuhalt <= 1'b1;
                ctlstate <= `CTL_STARTB;
            end
            "V": begin 
                cmdid <= `CMD_VIEW;
                ctlstate <= `CTL_READ0A;
            end
            default: ctlstate <= `CTL_BADCMD;
            endcase
        end
    end
    `CTL_READ0A: begin
        packouten <= 1'b0;
        // if character inbound, decode to hex and push into pack
        if (inbound) begin
            packinen <= 1'b1;
            ctlstate <= `CTL_READ0B;
        end
    end
    `CTL_READ0B: begin
        // if not full wait for next char
        packinen <= 1'b0;     
        ctlstate <= `CTL_READ0A;
        // else save pack to arg0 and reset
        if (full8) begin
            arg0 <= progdata[15:0];
            packouten <= 1'b1;
            // prog expects program data start, view - next param
            case (cmdid)
            `CMD_PROG: ctlstate <= `CTL_STARTB;
            `CMD_VIEW: ctlstate <= `CTL_READ0C;
            default: ctlstate <= `CTL_BADCMD;
            endcase
        end
    end
    `CTL_READ0C: begin
        // expect inbound ','
        if (inbound) ctlstate <= `CTL_READ1A;
    end
    `CTL_READ1A: begin
        packouten <= 1'b0;
        // if character inbound, decode to hex and push into pack
        if (inbound) begin
            packinen <= 1'b1;
            ctlstate <= `CTL_READ1B;
        end
    end
    `CTL_READ1B: begin
        // if not full wait for next char
        packinen <= 1'b0;     
        ctlstate <= `CTL_READ1A;
        // else save pack to arg1 and reset
        if (full8) begin
            arg1 <= progdata[15:0];
            packouten <= 1'b1;
            // if view then expect end of packet
            case (cmdid)
            `CMD_VIEW: ctlstate <= `CTL_ENDOFV;
            default: ctlstate <= `CTL_BADCMD;
            endcase
        end        
    end
    `CTL_READPA: begin
        packouten <= 1'b0;
        // if inbound, push to pack
        if (inbound) begin
            packinen <= 1'b1;
            ctlstate <= `CTL_READPB;
        end        
    end
    `CTL_READPB: begin
        // if not full loop
        packinen <= 1'b0;     
        ctlstate <= `CTL_READPF;
        // else send word to program memory
       
    end
    `CTL_READPF: begin
        ctlstate <= `CTL_READPA;
        if (full8) ctlstate <= `CTL_PCOMMA; 
    end
    `CTL_PCOMMA: begin
        progen <= 1'b1;
        packouten <= 1'b1;
        // wait for inbound char, then increment program address and loop
        if (inbound) begin
            progen <= 1'b0;
            packouten <= 1'b0;
            progaddr <= progaddr + 1'b1;
            ctlstate <= `CTL_READPA;
            if (data == "]") ctlstate <= `CTL_ENDOFR;
        end
    end
    `CTL_STARTB: begin
        progaddr <= 1'b1;
        ctlstate <= `CTL_READPA;
    end
    `CTL_ENDOFH: begin
        if (inbound) begin
            cpuhalt <= 1'b1;
            ctlstate <= `CTL_STARTP;
        end
    end
    `CTL_ENDOFZ: begin
        if (inbound) begin
            cpustart <= 1'b1;
            ctlstate <= `CTL_STARTP;
        end    
    end    
    `CTL_ENDOFS: begin
        if (inbound) begin
            cpustep <= 1'b1;
            ctlstate <= `CTL_STARTP;
        end    
    end    
    `CTL_ENDOFR: begin
        if (inbound) begin
            cpurst <= 1'b1;
            ctlstate <= `CTL_STARTP;
        end    
    end
    `CTL_ENDOFV: begin
        dvpage <= arg0[DVPBITS-1:0];
        pvpage <= arg1[PVPBITS-1:0];
        ctlstate <= `CTL_STARTP;
    end
    `CTL_BADCMD: begin
        // bad command, wait for end of packet and reset
        if (inbound && data == "\n") ctlstate <= `CTL_STARTP;
    end
    endcase

    if (!n_rst) begin
        ctlstate <= `CTL_STARTP;
        packinen <= 1'b0;
        packouten <= 1'b0;
        progen <= 1'b0;
        cpuhalt <= 1'b0;
        cpustart <= 1'b0;
        cpustep <= 1'b0;
        cpurst <= 1'b0;
    end
end

endmodule
