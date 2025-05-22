`timescale 1ns / 1ps
/*****************************************************************************
 *  Author: Piotr Kadziela
 *  Description:
 *      Basic built-in RAM with error checking. 
 *      Only 32-bit word aligined access is supported.
 *      Only one read or write operation is allowed at a time.
 *      Uses block memory if possible. 
 *****************************************************************************/

// TODO:
// - add support for 8-bit and 16-bit access (memory masking)
// - parametrize error handling
// - consider allowing simultaneous R/W

`define MEMORY_STATE_SUCCESS        2'b00   // No error
`define MEMORY_STATE_READ_WRITE     2'b01   // Simultaneous read and write error
`define MEMORY_STATE_OUT_OF_BOUNDS  2'b10   // Address out-of-bounds error
`define MEMORY_STATE_ALIGNMENT      2'b11   // Aliginment error

module memory #(
    parameter MEMORY_SIZE_WORDS = 1024,                     // Memory size in 32-bit words
    parameter INIT_FILE         = "",                       // Path to memory initialization file. Zero-initialized if none is provided.
    parameter ADDR_WIDTH        = $clog2(MEMORY_SIZE_WORDS) // Memory bus size. By default, the size needed to address MEMORY_SIZE_WORDS.
) (
    input               clk,

    input               r_en,   // read enable
    input       [31:0]  r_addr, // 32-bit address
    output reg  [31:0]  r_data, // 32-bits of data

    input               w_en,   // write enable
    input       [31:0]  w_addr, // 32-bit address
    input       [31:0]  w_data, // 32-bits of data

    output reg  [1:0]   state   // memory state (error codes)
);

(* ram_style = "block" *)
reg     [31:0]  mem [0:MEMORY_SIZE_WORDS-1];

assign r_addr_wrd       = r_addr[ADDR_WIDTH:2];
assign r_addr_offset    = r_addr[1:0];
assign w_addr_wrd       = w_addr[ADDR_WIDTH:2];
assign w_addr_offset    = w_addr[1:0];

always @(posedge clk) begin
    // Error checking
    if (r_en && w_en)
        state <= `MEMORY_STATE_READ_WRITE;
    else if ((r_en) && (r_addr_wrd >= MEMORY_SIZE_WORDS))
        state <= `MEMORY_STATE_OUT_OF_BOUNDS;
    else if ((w_en) && (w_addr_wrd >= MEMORY_SIZE_WORDS))
        state <= `MEMORY_STATE_OUT_OF_BOUNDS;
    else if ((r_en) && (r_addr_offset != 2'b00))
        state <= `MEMORY_STATE_ALIGNMENT;
    else if ((w_en) && (w_addr_offset != 2'b00))
        state <= `MEMORY_STATE_ALIGNMENT;
    
    // Memory operations
    else if (w_en) begin
        mem[w_addr[ADDR_WIDTH:0]] <= w_data;
        state <= `MEMORY_STATE_SUCCESS;
    end
    else if (r_en) begin
        r_data <= mem[r_addr[ADDR_WIDTH:0]];
        state <= `MEMORY_STATE_SUCCESS;
    end
end

initial begin
    state <= `MEMORY_STATE_SUCCESS;
    if (INIT_FILE != "") begin
        $readmemh(INIT_FILE, mem);
    end
    else begin: CLEAR_MEM
        integer i;
        for (i = 0; i < MEMORY_SIZE_WORDS; i = i + 1) mem[i] <= 32'h00000000;
    end
end

endmodule
