`timescale 1ns / 1ps
/*****************************************************************************
 *  Author: Piotr Kadziela
 *  Description:
 *      Branch Unit for RISC-V core.
 *****************************************************************************/

// TODO:
// - Consider adding states for branching operations (error handling)

`include "opcodes.vh"

module branch_unit (
    input               br_en,      // branch enable
    input       [2:0]   funct3,     // branch operation code
    input       [31:0]  br_data_a,  // branch comparison data 1
    input       [31:0]  br_data_b,  // branch comparison data 2

    output reg          br_taken    // true if branch is taken
);

always @* begin
    if (br_en) begin
        case (funct3)
            `FUNCT3_BEQ:     // Branch if EQual
                br_taken <= (br_data_a == br_data_b);
            `FUNCT3_BNE:     // Branch if Not Equal
                br_taken <= (br_data_a != br_data_b);
            `FUNCT3_BLT:     // Branch if Less Than
                br_taken <= ($signed(br_data_a) < $signed(br_data_b));
            `FUNCT3_BGE:     // Branch if Greater or Equal
                br_taken <= ($signed(br_data_a) >= $signed(br_data_b));
            `FUNCT3_BLTU:    // Branch if Less Than Unsigned
                br_taken <= (br_data_a < br_data_b);
            `FUNCT3_BGEU:    // Branch if Greater or Equal Unsigned
                br_taken <= (br_data_a >= br_data_b);
            default:        // error case, prevent latches  
                br_taken <= 1'b0;
        endcase
    end
    else br_taken <= 1'b0;
end


endmodule