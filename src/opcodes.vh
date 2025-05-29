// RV32I Base Integer Instruction Set:
// instruction  type    opcode          funct3          funct7          notes
//
// ADD          R       OP_ALU          FUNCT3_ADD_SUB  FUNCT7_NORMAL
// SUB          R       OP_ALU          FUNCT3_ADD_SUB  FUNCT7_SUB_SRA
// AND          R       OP_ALU          FUNCT3_AND      FUNCT7_NORMAL
// OR           R       OP_ALU          FUNCT3_OR       FUNCT7_NORMAL
// XOR          R       OP_ALU          FUNCT3_XOR      FUNCT7_NORMAL
// SLL          R       OP_ALU          FUNCT3_SLL      FUNCT7_NORMAL
// SRL          R       OP_ALU          FUNCT3_SRL_SRA  FUNCT7_NORMAL
// SRA          R       OP_ALU          FUNCT3_SRL_SRA  FUNCT7_SUB_SRA
// SLT          R       OP_ALU          FUNCT3_SLT      FUNCT7_NORMAL
// SLTU         R       OP_ALU          FUNCT3_SLTU     FUNCT7_NORMAL
//                                      
// ADDI         I       OP_ALUI         FUNCT3_ADD_SUB  FUNCT7_NORMAL   \
// ANDI         I       OP_ALUI         FUNCT3_AND      FUNCT7_NORMAL   |
// ORI          I       OP_ALUI         FUNCT3_OR       FUNCT7_NORMAL   |
// XORI         I       OP_ALUI         FUNCT3_XOR      FUNCT7_NORMAL   | These instructions do not have a funct7 field.
// SLLI         I       OP_ALUI         FUNCT3_SLL      FUNCT7_NORMAL   | However, they use imm[5:11] which has the same 
// SRLI         I       OP_ALUI         FUNCT3_SRL_SRA  FUNCT7_NORMAL   | layout as funct7.
// SRAI         I       OP_ALUI         FUNCT3_SRL_SRA  FUNCT7_SUB_SRA  | 
// SLTI         I       OP_ALUI         FUNCT3_SLT      FUNCT7_NORMAL   |
// SLTIU        I       OP_ALUI         FUNCT3_SLTU     FUNCT7_NORMAL   /
//                                                      
// LB           I       OP_LOAD         FUNCT3_LB       N/A
// LBU          I       OP_LOAD         FUNCT3_LBU      N/A
// LH           I       OP_LOAD         FUNCT3_LH       N/A
// LHU          I       OP_LOAD         FUNCT3_LHU      N/A
// LW           I       OP_LOAD         FUNCT3_LW       N/A
//                                                      
// SB           S       OP_STORE        FUNCT3_SB       N/A
// SH           S       OP_STORE        FUNCT3_SH       N/A
// SW           S       OP_STORE        FUNCT3_SW       N/A
//                                                      
// BEQ          B       OP_BRANCH       FUNCT3_BEQ      N/A
// BNE          B       OP_BRANCH       FUNCT3_BNE      N/A
// BGE          B       OP_BRANCH       FUNCT3_BGE      N/A
// BGEU         B       OP_BRANCH       FUNCT3_BGEU     N/A
// BLT          B       OP_BRANCH       FUNCT3_BLT      N/A
// BLTU         B       OP_BRANCH       FUNCT3_BLTU     N/A
//                                                      
// JAL          J       OP_JAL          N/A             N/A
// JALR         I       OP_JALR         FUNCT3_EMPTY    N/A
//                                                      
// ECALL        I       OP_ENVIRONMENT  FUNCT3_EMPTY    N/A
// EBREAK       I       OP_ENVIRONMENT  FUNCT3_EMPTY    N/A
//                                                      
// LUI          U       OP_LUI          N/A             N/A
// AUIPC        U       OP_AUIPC        N/A             N/A
// FENCE        TODO    TODO            N/A             N/A


// OPCODES
`define OP_ALU          7'b0110011  // ALU Instructions - R-Type
`define OP_ALUI         7'b0010011  // ALU Immediate Instructions - I-Type
`define OP_LOAD         7'b0000011  // Load Instructions (LB, LH, LW, LBU, LHU) - I-Type
`define OP_STORE        7'b0100011  // Store Instructions (SB, SH, SW) - S-Type
`define OP_JAL          7'b1101111  // Jump and Link - J-Type 
`define OP_JALR         7'b1100111  // Jump and Link Register - I-Type
`define OP_BRANCH       7'b1100011  // Branch Instructions (BEQ, BNE, BLT, etc.)- B-Type
`define OP_LUI          7'b0110111  // Load Upper Immediate - U-Type
`define OP_AUIPC        7'b0010111  // Add Upper Immediate to PC - U-Type
`define OP_ENVIRONMENT  7'b1110011  // Environmental Call (ECALL, EBREAK) - I-Type

// JALR and ENVIRONMENT opcodes do not use funct3
`define FUNCT3_EMPTY    3'b000

// funct3 codes for OP_ALU/OP_ALUI
`define FUNCT3_ADD_SUB  3'b000      // Add / Subtract
`define FUNCT3_AND      3'b111      // Bitwise AND
`define FUNCT3_OR       3'b110      // Bitwise OR
`define FUNCT3_XOR      3'b100      // Bitwise XOR
`define FUNCT3_SLL      3'b001      // Shift Left Logical (fill with 0)
`define FUNCT3_SRL_SRA  3'b101      // Shift Right Logical (fill with 0) / Shift Right Arithmetic (fill with sign bit)
`define FUNCT3_SLT      3'b010      // Set Less Than (set to 1 if op_a < op_b)
`define FUNCT3_SLTU     3'b011      // Set Less Than Unsigned (set to 1 if op_a < op_b)

// funct7 codes for ALU instructions
`define FUNCT7_ALU_NORM 7'b0000000  // ADD, XOR, OR, AND, SLL, SRL, SLT, SLTU
`define FUNCT7_SUB_SRA  7'b0100000  // SUB, SRA

// funct3 codes for OP_LOAD
`define FUNCT3_LB       3'b000      // Load Byte
`define FUNCT3_LH       3'b001      // Load Halfword
`define FUNCT3_LW       3'b010      // Load Word
`define FUNCT3_LBU      3'b100      // Load Byte Unsigned
`define FUNCT3_LHU      3'b101      // Load Halfword Unsigned

// funct3 codes for OP_STORE
`define FUNCT3_SB       3'b000      // Store Byte
`define FUNCT3_SH       3'b001      // Store Halfword
`define FUNCT3_SW       3'b010      // Store Word

// funct3 codes for OP_BRANCH
`define FUNCT3_BEQ      3'b000      // Branch if EQual
`define FUNCT3_BNE      3'b001      // Branch if Not equal
`define FUNCT3_BLT      3'b100      // Branch if Less Than
`define FUNCT3_BGE      3'b101      // Branch if Greater than or Equal
`define FUNCT3_BLTU     3'b110      // Branch if Less Than unsigned
`define FUNCT3_BGEU     3'b111      // Branch if Greater than or Equal Unsigned

// instruction type matching patterns
`define OPCODE_TYPE_R   `OP_ALU
`define OPCODE_TYPE_I   `OP_ALUI,`OP_LOAD,`OP_JALR,`OP_ENVIRONMENT
`define OPCODE_TYPE_S   `OP_STORE
`define OPCODE_TYPE_B   `OP_BRANCH
`define OPCODE_TYPE_J   `OP_JAL
`define OPCODE_TYPE_U   `OP_LUI,`OP_AUIPC