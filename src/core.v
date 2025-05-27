`timescale 1ns / 1ps
/*****************************************************************************
 *  Author: Piotr Kadziela
 *  Description:
 *      The implementation of RISC-V core capable of executing RV32I 
 *      instruction set. For now this is a single-cycle implementation.

 *      The core executes each instruction in a single cycle (that is 5 clock 
 *      ticks long). There are 5 stages:
 *      1. Instruction Fetch (IF) - fetch the instruction from memory
 *      2. Instruction Decode (ID) - decode the instruction and read registers
 *      3. Execute (EX) - execute the instruction (ALU, branch unit, etc.)
 *      4. Memory Access (MEM) - access memory if needed
 *      5. Write Back (WB) - write the result back to the register file
 *****************************************************************************/

// TODO:
// - Correcly implement reseting in all of the modules (including memory wipe)
// - ECALL and EBREAK instructions
// - FENCE instruction
// - interrupts
// - Load/Store half word and byte
// - check for correct endianness handling
// - define the correct naming convention for the stages (i.e. if STATE_FETCH actions are 
//      called *before* or *after* fetching)

`include "opcodes.vh"

`define CORE_STATE_INIT         3'b000
`define CORE_STATE_FETCH        3'b001
`define CORE_STATE_DECODE       3'b010
`define CORE_STATE_EXECUTE      3'b011
`define CORE_STATE_MEMORY       3'b100
`define CORE_STATE_WRITEBACK    3'b101
`define CORE_STATE_HALT         3'b110
`define CORE_STATE_ERROR        3'b111

module core (
    input               clk,
    input               rst_n,

    // Instruction memory interface
    output reg          mem_instr_r_en,     // read enable
    output reg  [31:0]  mem_instr_r_addr,   // 32-bit address
    input       [31:0]  mem_instr_r_data,   // 32-bits of data

    output reg          mem_instr_w_en,     // write enable
    output      [31:0]  mem_instr_w_addr,   // 32-bit address, hardwired to PC
    output reg  [31:0]  mem_instr_w_data,   // 32-bits of data

    // Data memory interface
    output reg          mem_data_r_en,      // read enable
    output reg  [31:0]  mem_data_r_addr,    // 32-bit address
    input       [31:0]  mem_data_r_data,    // 32-bits of data

    output reg          mem_data_w_en,      // write enable
    output reg  [31:0]  mem_data_w_addr,    // 32-bit address
    output reg  [31:0]  mem_data_w_data,    // 32-bits of data

    // Debug interface, all the outputs are hardwired to the core parts
    output      [2:0]   dbg_state,          // state of the core
    output      [31:0]  dbg_pc,             // debug pc
    input       [4:0]   dbg_reg_sel,        // debug reg selector
    output      [31:0]  dbg_reg_data,       // debug reg data

    input       [7:0]   io_in,              // IO input pins
    output      [7:0]   io_out              // IO output pins
);

reg     [2:0]   state;          // state of the core
reg     [31:0]  pc;             // program counter

assign mem_instr_w_addr = pc;   // We read from the instruction memory only at the PC address

reg     [31:0]  instr;          // buffer for the currently executed instruction

wire    [6:0]   opcode;         // opcode
wire    [4:0]   rd;             // destination register
wire    [2:0]   funct3;         // function code (3 bit)
wire    [4:0]   rs1;            // source register 1  
wire    [4:0]   rs2;            // source register 2
wire    [6:0]   funct7;         // function code (7 bit)
wire            alu_src_sel;    // source select for ALU (0 - rs2, 1 - immediate)

assign opcode       = instr[6:0];
assign rd           = instr[11:7];
assign funct3       = instr[14:12];
assign rs1          = instr[19:15];
assign rs2          = instr[24:20];
assign funct7       = instr[31:25];
assign alu_src_sel  = opcode[6]; // differentiate between R-type and I-type instructions

// regfile interface
wire    [31:0]  r_data_1;       // data from the first register
wire    [31:0]  r_data_2;       // data from the second register
reg     [31:0]  w_data;         // data to write
reg             w_en;           // write enable

// imm_decoder interface
wire    [31:0]  imm;            // immediate value from imm_decoder

// ALU interface
reg             alu_en;         // ALU enable
wire    [31:0]  alu_res;        // result of the ALU operation

// Branch Unit interface
reg             br_en;          // branch enable
wire            br_taken;       // branch taken

assign dbg_state = state;
assign dbg_pc = pc;

regfile regfile1 (
    .clk(clk),
    .rst_n(rst_n),

    .r_sel_1(rs1),
    .r_sel_2(rs2),
    .r_data_1(r_data_1),
    .r_data_2(r_data_2),

    .w_en(w_en),
    .w_sel(rd),
    .w_data(w_data),
    
    .dbg_reg_sel(dbg_reg_sel),
    .dbg_reg_data(dbg_reg_data),

    .io_in(io_in),
    .io_out(io_out)
);

imm_decoder imm_decoder1 (
    .clk(clk),
    .rst_n(rst_n),

    .instr(instr),
    .imm(imm)
);

alu alu1 (
    .clk(clk),
    .rst_n(rst_n),

    .funct3(funct3),
    .funct7(funct7),
    
    .alu_en(alu_en),
    .src_sel(alu_src_sel),
    .reg_data_1(r_data_1),
    .reg_data_2(r_data_2),
    .immediate(imm),

    .alu_res(alu_res)
);

branch_unit branch_unit1 (
    .clk(clk),
    .rst_n(rst_n),

    .br_en(br_en),
    .funct3(funct3),
    .br_data_a(r_data_1),
    .br_data_b(r_data_2),
    .br_taken(br_taken)
);

always @(posedge clk) begin 
    case(state)
        `CORE_STATE_INIT: begin
            // Reset the program counter
            pc <= 32'h00000000;

            // Prepare for fetching the first instruction
            mem_instr_r_en <= 1'b1;

            state <= `CORE_STATE_FETCH;
        end

        `CORE_STATE_FETCH: begin
            // Read from instruction memory
            instr <= mem_instr_r_data;
            mem_instr_r_en <= 1'b0;
            state <= `CORE_STATE_DECODE;
        end

        `CORE_STATE_DECODE: begin
            // Decoding is now handled by the imm_decoder.
            // Registers are being automaticly read from the register file as well.
            // We need to wait for the regfile and imm_decoder to finish, and possibly 
            // enable the Branch Unit or ALU
            case (opcode)
                `OP_ALU, `OP_ALUI: begin
                    // ALU instructions, we need to enable the ALU
                    alu_en <= 1'b1;
                end

                `OP_BRANCH: begin
                    // B-type instructions, we need to enable the Branch Unit
                    br_en <= 1'b1;
                end

                default: begin
                    // For any other instruction, we need to disable the Branch Unit and ALU
                    br_en <= 1'b0;
                    alu_en <= 1'b0;
                end
            endcase
            state <= `CORE_STATE_EXECUTE;
        end

        `CORE_STATE_EXECUTE: begin
            case (opcode)
                `OP_ALU, `OP_ALUI, `OP_BRANCH: begin
                    // Branching Unit/ALU is working. We do not need to do anything here.
                    state <= `CORE_STATE_MEMORY;
                end

                `OP_LOAD: begin
                    // Load instructions, we need to enable the data memory read
                    mem_data_r_en <= 1'b1;
                    mem_data_r_addr <= r_data_1 + imm;
                    state <= `CORE_STATE_MEMORY;
                end
                `OP_STORE: begin
                    // Store instructions, we need to enable the data memory write
                    mem_data_w_en <= 1'b1;
                    mem_data_w_addr <= r_data_1 + imm;
                    mem_data_w_data <= r_data_2;
                    state <= `CORE_STATE_MEMORY;
                end

                `OP_JAL: begin
                    // J-type instructions, we need to update the PC
                    // Unconditional jump, we just add the immediate value to the PC
                    pc <= pc + imm;
                    state <= `CORE_STATE_MEMORY;
                end
                `OP_JALR: begin
                    // JALR instruction, we need to update the PC
                    // Unconditional jump with link-register:
                    //   - add the immediate value to the register value
                    //   - set the least significant bit to 0
                    //   - set the PC to the result
                    //   - set the link register to PC + 4
                    pc  <= (r_data_1 + imm) & 32'hFFFFFFFE;
                    w_data <= (r_data_1 + imm) & 32'hFFFFFFFE + 4;
                    state <= `CORE_STATE_MEMORY;
                end

                `OP_LUI: begin
                    // LUI instruction, we need to update the register with an immediate value
                    w_data <= imm;
                    state <= `CORE_STATE_MEMORY;
                end
                `OP_AUIPC: begin
                    // AUIPC instruction, we need to add the immediate value to the PC
                    // and write it to the register
                    w_data <= pc + imm;
                    state <= `CORE_STATE_MEMORY;
                end

                `OP_ENVIRONMENT: begin
                    // ECALL or EBREAK instruction, for now we just halt the core
                    state <= `CORE_STATE_HALT;
                end

                default: begin
                    // Error state for unsupported opcodes
                    state <= `CORE_STATE_ERROR;
                end
            endcase

            // After executing the instruction, we need to disable the ALU and Branch Unit
            alu_en <= 1'b0;
            br_en <= 1'b0;
        end

        `CORE_STATE_MEMORY: begin 
            if(opcode == `OP_LOAD) begin
                // In case of load instruction, we need to read the data from memory into the 
                // register file.
                w_data <= mem_data_r_data;
            end
            
            // In case of any other instruction, we just wait.

            // After memory access, we need to disable the data memory read/write
            mem_data_r_en <= 1'b0;
            mem_data_w_en <= 1'b0;

            // We might need to prepare for a writeback to the register file in the next state
            case (opcode)
                `OP_ALU, `OP_ALUI: begin
                    w_en <= 1'b1;
                    w_data <= alu_res;
                end
                `OP_LOAD, `OP_JALR, `OP_LUI, `OP_AUIPC: begin
                    w_en <= 1'b1;
                end
                default: begin
                    // No writeback needed for other instructions
                    w_en <= 1'b0;
                end
            endcase

            state <= `CORE_STATE_WRITEBACK;
        end

        `CORE_STATE_WRITEBACK: begin
            // If w_en is set, the regfile is now writing. We need to disable w_en after use.
            w_en <= 1'b0;

            // Prepare for fetching the next instruction
            if (opcode == `OP_BRANCH && br_taken) begin
                // Branch taken, we need to update the PC
                pc <= pc + imm + 4;
            end
            else begin
                // No branch taken, we just increment the PC
                pc <= pc + 4;
            end
            mem_instr_r_en <= 1'b1;

            state <= `CORE_STATE_FETCH;
        end

        `CORE_STATE_ERROR, `CORE_STATE_HALT: begin 
            // Error or halt state, we do nothing and wait for reset
        end
    endcase
end

endmodule
