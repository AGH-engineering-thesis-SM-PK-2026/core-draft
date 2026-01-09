`timescale 1ns / 1ps
/*****************************************************************************
 *  Author: Piotr Kadziela
 *  Description:
 *      Decoder for immediate values in RISC-V I/S/B/U/J-type instructions.
 *****************************************************************************/

`include "opcodes.vh"

module imm_decoder (
    input       [31:0]  instr,         // instruction to decode
    output reg  [31:0]  imm            // immediate value, decoded and sign-extended
);

wire    [6:0] opcode;
assign opcode = instr[6:0];

always @* begin
    case (opcode)
        `OPCODE_TYPE_R:     // R-type instruction, no immediate
            imm = 32'b0; 
        `OPCODE_TYPE_I:     // I-type immediate value
            imm = {{21{instr[31]}}, instr[30:20]};
        `OPCODE_TYPE_S:     // S-type immediate value
            imm = {{21{instr[31]}}, instr[30:25], instr[11:7]};
        `OPCODE_TYPE_B:     // B-type immediate value
            imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
        `OPCODE_TYPE_J:     // J-type immediate value
            imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
        `OPCODE_TYPE_U:     // U-type immediate value
            imm = {instr[31:12], 12'b0};
        default:            // error case, prevent latches
            imm = 32'b0101010101010101;
    endcase
end


endmodule