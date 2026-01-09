// Error states for memory operations
`define MEMORY_STATE_OK             2'b00   // No error
`define MEMORY_STATE_OUT_OF_BOUNDS  2'b01   // Address out-of-bounds error
`define MEMORY_STATE_ALIGNMENT      2'b10   // Alignment error

// Memory access modes for load/store operations (analogous to funct3 field)
`define MODE_SB                     2'b00   // load/store byte
`define MODE_SH                     2'b01   // load/store half-word
`define MODE_SW                     2'b10   // load/store word