`timescale 1ns / 1ps

module dbgsel (
    input wire [6:0] dbgsel,
    input wire dbgreaden,
    input wire [31:0] regin,
    input wire [31:0] datain,
    input wire [31:0] pcin,
    output reg [31:0] dbgout,
    output wire [4:0] regsel,
    output wire [4:0] datasel,
    output wire dataen
);

assign dataen = dbgsel[6:5] == 2'b10 ? dbgreaden : 1'b0;

always @(*) begin
    case (dbgsel[6:5])
    2'b00: dbgout = regin;
    2'b01: dbgout = datain;
    default: begin
        dbgout = 1'b0;
        if (dbgsel == 7'b1000000) dbgout = pcin;
    end
    endcase
end

endmodule
