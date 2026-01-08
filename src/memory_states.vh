`define MEMORY_STATE_SUCCESS        2'b00   // No error
`define MEMORY_STATE_READ_WRITE     2'b01   // Simultaneous read and write error
`define MEMORY_STATE_OUT_OF_BOUNDS  2'b10   // Address out-of-bounds error
`define MEMORY_STATE_ALIGNMENT      2'b11   // Aliginment error