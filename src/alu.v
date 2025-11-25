`timescale 1ns / 1ps
/*****************************************************************************
 *  Author: Piotr Kadziela
 *  Description:
 *      Arithmetic Logic Unit (ALU) for RISC-V core.
 *****************************************************************************/

// TODO:
// - Add states for ALU operations (error handling)
// - Check for correct handling of arguments (eg. shift amounts, etc.)

`include "opcodes.vh"

module alu (
    input       [2:0]   funct3,         // 3-bit function code
    input       [6:0]   funct7,         // 7-bit function code

    input               alu_en,         // ALU enable (to prevent overwriting result)
    input               src_sel,        // source selection for second operand: 1 - rs2, 0 - immediate
    input       [31:0]  reg_data_1,     // first operand
    input       [31:0]  reg_data_2,     // second operand (rs2)
    input       [31:0]  immediate,      // second operand (immediate value)

    output reg  [31:0]  alu_res         // result of the operation
);

wire    [31:0]  op_a;
wire    [31:0]  op_b;
wire    [4:0]   shamt;          // shift amount - lower 5 bits of the second operand for shift operations
wire            alt_action;     // alternate action for current funct3, eg. sub instead of add

assign op_a = reg_data_1;
assign op_b = src_sel ? reg_data_2 : immediate;
assign shamt = op_b[4:0];
assign alt_action = (src_sel && funct7 == `FUNCT7_SUB_SRA) ? 1'b1 : 1'b0;

always @* begin
    if(alu_en) begin
        case (funct3)
            `FUNCT3_ADD_SUB: begin
                if(alt_action) begin     // Subtraction
                    alu_res = op_a - op_b;
                    $display("alu %0d - %0d = %0d", op_a, op_b, alu_res);
                end else begin           // Addition
                    alu_res = op_a + op_b;
                    $display("alu %0d + %0d = %0d", op_a, op_b, alu_res);
                end
            end
            `FUNCT3_AND: begin           // Bitwise AND
                alu_res = op_a & op_b;
                $display("alu %0d & %0d = %0d", op_a, op_b, alu_res);
            end
            `FUNCT3_OR: begin            // Bitwise OR
                alu_res = op_a | op_b;
                $display("alu %0d | %0d = %0d", op_a, op_b, alu_res);
            end
            `FUNCT3_XOR: begin           // Bitwise XOR
                alu_res = op_a ^ op_b;
                $display("alu %0d ^ %0d = %0d", op_a, op_b, alu_res);
            end
            `FUNCT3_SLL: begin           // Shift Left Logical (fill with 0)
                alu_res = op_a << shamt;
                $display("alu %0d << %0d = %0d", op_a, shamt, alu_res);
            end
            `FUNCT3_SLT: begin           // Set Less Than (set to 1 if op_a < op_b)
                alu_res = ($signed(op_a) < $signed(op_b)) ? 32'b1 : 32'b0;
                $display("alu %0d < %0d = %0d (signed)", op_a, op_b, alu_res);
            end
            `FUNCT3_SLTU: begin          // Set Less Than Unsigned (set to 1 if op_a < op_b)
                alu_res = (op_a < op_b) ? 32'b1 : 32'b0;
                $display("alu %0d < %0d = %0d (unsigned)", op_a, op_b, alu_res);
            end
            default:                // Default case to prevent latches
                alu_res = 32'b0;
        endcase
    end
    else alu_res = 32'b0;
end

endmodule
