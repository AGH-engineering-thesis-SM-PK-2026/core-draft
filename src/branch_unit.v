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
            `FUNCT3_BEQ: begin    // Branch if EQual
                br_taken <= (br_data_a == br_data_b);
                $display("branch == %s", br_taken ? "taken" : "skip");
            end
            `FUNCT3_BNE: begin    // Branch if Not Equal
                br_taken <= (br_data_a != br_data_b);
                $display("branch != %s", br_taken ? "taken" : "skip");
            end
            `FUNCT3_BLT: begin    // Branch if Less Than
                br_taken <= ($signed(br_data_a) < $signed(br_data_b));
                $display("branch <S %s", br_taken ? "taken" : "skip");
            end
            `FUNCT3_BGE: begin    // Branch if Greater or Equal
                br_taken <= ($signed(br_data_a) >= $signed(br_data_b));
                $display("branch >=S %s", br_taken ? "taken" : "skip");
            end
            `FUNCT3_BLTU: begin   // Branch if Less Than Unsigned
                br_taken <= (br_data_a < br_data_b);
                $display("branch <U %s", br_taken ? "taken" : "skip");
            end
            `FUNCT3_BGEU: begin   // Branch if Greater or Equal Unsigned
                br_taken <= (br_data_a >= br_data_b);
                $display("branch >=U %s", br_taken ? "taken" : "skip");
            end
            default: begin       // error case, prevent latches  
                br_taken <= 1'b0;
                $display("branch UNKNOWN!");
            end
        endcase
    end
    else br_taken <= 1'b0;
end


endmodule