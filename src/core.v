`timescale 1ns / 1ps
/*****************************************************************************
 *  Author: Piotr Kadziela
 *  Description:
 *      The implementation of  a single-cycle RISC-V core capable of executing  
 *      RV32I instruction set.

 *      The core executes each instruction in a single cycle (that is 5 clock 
 *      ticks long). There are 5 stages:
 *      1. Instruction Fetch (IF) - fetch the instruction from memory
 *      2. Instruction Decode (ID) - decode the instruction and read registers
 *      3. Execute (EX) - execute the instruction (ALU, branch unit, etc.)
 *      4. Memory Access (MEM) - access memory if needed
 *      5. Write Back (WB) - write the result back to the register file
 *****************************************************************************/

// TODO:
// - Correcly implement reseting in all of the modules
// - ECALL and EBREAK instructions
// - FENCE instruction
// - interrupts
// - Load/Store half word and byte
// - check for correct endianness handling
// - CLOCK ENABLE

`include "opcodes.vh"

`define CORE_STATE_INIT         4'b0000
`define CORE_STATE_FETCH        4'b0001
`define CORE_STATE_DECODE       4'b0010
`define CORE_STATE_EXECUTE      4'b0011
`define CORE_STATE_MEMORY       4'b0100
`define CORE_STATE_WRITEBACK    4'b0101
`define CORE_STATE_HALT         4'b0110
`define CORE_STATE_ERROR        4'b0111
`define TMP_STATE_FETCH_DELAYED 4'b1001

module core (
    input               clk,                
    input               rst_n,              // reset on low
    input               clk_enable,         // 
    output              cycle_end,          // high on last tick of the cycle (WB or INIT stage)

    // Instruction memory interface
    output reg          mem_instr_r_en,     // read enable
    output      [31:0]  mem_instr_r_addr,   // 32-bit address
    input       [31:0]  mem_instr_r_data,   // 32-bits of data

    output reg          mem_instr_w_en,     // write enable
    output reg  [31:0]  mem_instr_w_addr,   // 32-bit address, hardwired to PC
    output reg  [31:0]  mem_instr_w_data,   // 32-bits of data

    // Data memory interface
    output reg          mem_data_r_en,      // read enable
    output reg  [31:0]  mem_data_r_addr,    // 32-bit address
    input       [31:0]  mem_data_r_data,    // 32-bits of data

    output reg          mem_data_w_en,      // write enable
    output reg  [31:0]  mem_data_w_addr,    // 32-bit address
    output reg  [31:0]  mem_data_w_data,    // 32-bits of data

    // Debug interface, all the outputs are hardwired to the core parts
    output      [3:0]   dbg_state,          // state of the core
    output      [31:0]  dbg_pc,             // debug pc
    input       [4:0]   dbg_reg_sel,        // debug reg selector
    output      [31:0]  dbg_reg_data        // debug reg data
);

reg     [3:0]   state;              // state of the core
reg     [31:0]  pc;                 // program counter

assign mem_instr_r_addr = pc;       // We read from the instruction memory only at the PC address
assign cycle_end = (state == `CORE_STATE_WRITEBACK || state == `CORE_STATE_INIT);

reg     [31:0]  instr;              // buffer for the currently executed instruction

wire    [6:0]   opcode;             // opcode
wire    [4:0]   rd;                 // destination register
wire    [2:0]   funct3;             // function code (3 bit)
wire    [4:0]   rs1;                // source register 1  
wire    [4:0]   rs2;                // source register 2
wire    [6:0]   funct7;             // function code (7 bit)
wire            alu_src_sel;        // source select for ALU (0 - rs2, 1 - immediate)

assign opcode       = instr[6:0];
assign rd           = instr[11:7];
assign funct3       = instr[14:12];
assign rs1          = instr[19:15];
assign rs2          = instr[24:20];
assign funct7       = instr[31:25];
assign alu_src_sel  = opcode[5];    // differentiate between R-type and I-type instructions

// regfile interface
wire    [31:0]  reg_r_data_1;       // data from the first register
wire    [31:0]  reg_r_data_2;       // data from the second register
reg     [31:0]  reg_w_data;         // data to write
reg             reg_w_en;           // write enable

// imm_decoder interface
wire    [31:0]  imm;                // immediate value from imm_decoder

// ALU interface
reg             alu_en;             // ALU enable
wire    [31:0]  alu_res;            // result of the ALU operation

// Branch Unit interface
reg             br_en;              // branch enable
wire            br_taken;           // branch taken

assign dbg_state = state;
assign dbg_pc = pc;

regfile regfile1 (
    .clk(clk),
    .rst_n(rst_n),

    .r_sel_1(rs1),
    .r_sel_2(rs2),
    .r_data_1(reg_r_data_1),
    .r_data_2(reg_r_data_2),

    .w_en(reg_w_en),
    .w_sel(rd),
    .w_data(reg_w_data),
    
    .dbg_reg_sel(dbg_reg_sel),
    .dbg_reg_data(dbg_reg_data)
);

imm_decoder imm_decoder1 (
    .instr(instr),
    .imm(imm)
);

alu alu1 (
    .funct3(funct3),
    .funct7(funct7),
    
    .alu_en(alu_en),
    .src_sel(alu_src_sel),
    .reg_data_1(reg_r_data_1),
    .reg_data_2(reg_r_data_2),
    .immediate(imm),

    .alu_res(alu_res)
);

branch_unit branch_unit1 (
    .br_en(br_en),
    .funct3(funct3),
    .br_data_a(reg_r_data_1),
    .br_data_b(reg_r_data_2),
    .br_taken(br_taken)
);

always @(posedge clk) begin
    $monitor("PC <- [%h]", pc);

    if (!rst_n) begin
        state <= `CORE_STATE_INIT;
        $display("==== CORE INIT ====");
    end
    else begin
        case(state)
            `CORE_STATE_INIT: begin
                // Reset the program counter
                pc <= 32'h00000000;

                // Prepare for fetching the first instruction
                mem_instr_r_en <= 1'b1;

                state <= `CORE_STATE_FETCH;
            end

            `CORE_STATE_FETCH: begin
                // Register file has finished reading the registers by now.
                // We can also disable instruction memory read, as we will get the data after this cycle.
                mem_instr_r_en <= 1'b0;
                reg_w_en <= 1'b0;

                state <= `CORE_STATE_DECODE;
            end

            `CORE_STATE_DECODE: begin
                // We can now write the imem response into the instruction register.
                instr <= mem_instr_r_data;
                // Decoding is now handled by the imm_decoder.
                // Registers are being automaticly read from the register file as well.
                // We need to give this cycle for the regfile and imm_decoder to finish.
                state <= `CORE_STATE_EXECUTE;
            end

            `CORE_STATE_EXECUTE: begin
                case (opcode)
                    `OP_ALU, `OP_ALUI: begin
                        // Registers are set by now, we need to enable ALU.
                        alu_en <= 0'b1;
                        state <= `CORE_STATE_MEMORY;
                        $display("instr [ALU/ALUI]");
                    end

                    `OP_BRANCH: begin
                        // Registers are set by now, we need to enable BU.
                        br_en <= 0'b1;
                        state <= `CORE_STATE_MEMORY;
                        $display("instr [BRANCH]");

                    end

                    `OP_LOAD: begin
                        // Load instructions, we need to enable the data memory read
                        mem_data_r_en <= 1'b1;
                        mem_data_r_addr <= reg_r_data_1 + imm;
                        state <= `CORE_STATE_MEMORY;
                        $display("instr [LOAD]");
                    end
                    `OP_STORE: begin
                        // Store instructions, we need to enable the data memory write
                        mem_data_w_en <= 1'b1;
                        mem_data_w_addr <= reg_r_data_1 + imm;
                        mem_data_w_data <= reg_r_data_2;
                        state <= `CORE_STATE_MEMORY;
                        $display("instr [STORE]");
                    end

                    `OP_JAL: begin
                        // J-type instructions, we need to update the PC
                        // Unconditional jump, we just add the immediate value to the PC
                        pc <= pc + imm;
                        state <= `CORE_STATE_MEMORY;
                        $display("instr [JAL]");
                    end
                    `OP_JALR: begin
                        // JALR instruction, we need to update the PC
                        // Unconditional jump with link-register:
                        //   - add the immediate value to the register value
                        //   - set the least significant bit to 0
                        //   - set the PC to the result
                        //   - set the link register to PC + 4
                        pc  <= (reg_r_data_1 + imm) & 32'hFFFFFFFE;
                        reg_w_data <= (reg_r_data_1 + imm) & 32'hFFFFFFFE + 4;
                        state <= `CORE_STATE_MEMORY;
                        $display("instr [JALR]");
                    end

                    `OP_LUI: begin
                        // LUI instruction, we need to update the register with an immediate value
                        reg_w_data <= imm;
                        state <= `CORE_STATE_MEMORY;
                        $display("instr [LUI]");
                    end
                    `OP_AUIPC: begin
                        // AUIPC instruction, we need to add the immediate value to the PC
                        // and write it to the register
                        reg_w_data <= pc + imm;
                        state <= `CORE_STATE_MEMORY;
                        $display("instr [AUIPC]");
                    end

                    `OP_ENVIRONMENT: begin
                        // ECALL or EBREAK instruction, for now we just halt the core
                        state <= `CORE_STATE_HALT;
                        $display("instr [ECALL/EBREAK]");
                    end

                    default: begin
                        // Error state for unsupported opcodes
                        state <= `CORE_STATE_ERROR;
                        $display("UNKNOWN INSTR OPCODE! [%h]", instr);
                    end
                endcase
            end

            `CORE_STATE_MEMORY: begin 
                // Nothing to do here - we just wait for memory operations to complete.
                // In case of any other instructions, we just pass through this state.
                state <= `CORE_STATE_WRITEBACK;
            end

            `CORE_STATE_WRITEBACK: begin
                case (opcode)
                    `OP_ALU, `OP_ALUI: begin
                        // ALU instructions, we need to write the result back to the register file
                        reg_w_data <= alu_res;
                        reg_w_en <= 1'b1;
                    end
                    `OP_LOAD: begin
                        // Load instruction, we need to write the data from memory into the register file.
                        reg_w_data <= mem_data_r_data;
                        reg_w_en <= 1'b1;
                    end
                    `OP_JALR, `OP_LUI, `OP_AUIPC: begin
                        // JALR, LUI and AUIPC instructions, we need to write the result back to the register file.
                        // The data was already prepared in the reg_w_data during the EXECUTE stage.
                        reg_w_en <= 1'b1;
                    end
                    default: begin
                        // No writeback needed for other instructions
                        reg_w_en <= 1'b0;
                    end
                endcase

                // Memory operations, ALU and BU are done by now, we can disable them
                mem_data_r_en <= 1'b0;
                mem_data_w_en <= 1'b0;
                alu_en <= 1'b0;
                br_en <= 1'b0;

                // Prepare for fetching the next instruction
                if (opcode == `OP_BRANCH && br_taken) begin
                    // If a branch has been taken we load the jump address into the PC
                    pc <= pc + imm;
                end
                else begin
                    // In other cases we just increment the PC by 4
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
end

initial begin
    state <= `CORE_STATE_INIT;
    pc <= 32'b0000;
    instr <= 32'b0;
end

initial begin
    state <= `CORE_STATE_INIT;
    pc <= 32'b0000;
    instr <= 32'b0;
end

endmodule
