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
// - parametrize error handling (generate)
// - consider allowing simultaneous R/W (tricky, 
//   would have to ensure that no read and write occur in the same ram block, 
//   to prevent corruption)
// - add extra reg buffering for better timing

`define MEMORY_STATE_SUCCESS        2'b00   // No error
`define MEMORY_STATE_READ_WRITE     2'b01   // Simultaneous read and write error
`define MEMORY_STATE_OUT_OF_BOUNDS  2'b10   // Address out-of-bounds error
`define MEMORY_STATE_ALIGNMENT      2'b11   // Aliginment error

module memory #(
    parameter NAME              = "",
    parameter MEMORY_SIZE_WORDS = 1024,                     // Memory size in 32-bit words
    parameter INIT_FILE         = "",                       // Path to memory initialization file. Zero-initialized if none is provided.
    parameter ADDR_WIDTH        = $clog2(MEMORY_SIZE_WORDS*4) // Memory bus size. By default, the size needed to address MEMORY_SIZE_WORDS.
) (
    input               clk,

    input               r_en,   // read enable
    input       [ADDR_WIDTH-1:0]  r_addr, // 32-bit address
    output      [31:0]  r_data, // 32-bits of data
    input        [1:0]  r_bmul, // how many bytes (0->1, 1->2, 2->4)

    input               w_en,   // write enable
    input       [ADDR_WIDTH-1:0]  w_addr, // 32-bit address
    input       [31:0]  w_data, // 32-bits of data
    input        [1:0]  w_bmul, // how many bytes (0->1, 1->2, 2->4)

    output reg  [1:0]   state   // memory state (error codes)
);

(* ram_style = "block" *)
reg     [31:0]  mem [0:MEMORY_SIZE_WORDS-1];


wire    [ADDR_WIDTH-3:0]  r_addr_wrd;
wire    [1:0]   r_addr_offset;
wire    [ADDR_WIDTH-3:0]  w_addr_wrd;
wire    [1:0]   w_addr_offset;

assign r_addr_wrd       = r_addr[ADDR_WIDTH-1:2];
assign r_addr_offset    = r_addr[1:0];
assign w_addr_wrd       = w_addr[ADDR_WIDTH-1:2];
assign w_addr_offset    = w_addr[1:0];

wire [3:0] w_strb;

wbmul i_wbmul (
    .bmul(w_bmul),
    .boff(w_addr_offset),
    .strb(w_strb)
);

wire [31:0] w_data_align;
reg [31:0] r_data_unalign;

rdconv i_rdconv (
    .bmul(r_bmul),
    .aoff(r_addr_offset),
    .in(r_data_unalign),
    .out(r_data)
);

wdconv i_wdconv (
    .bmul(w_bmul),
    .boff(w_addr_offset),
    .in(w_data),
    .out(w_data_align)
);

integer i;
always @(posedge clk) begin
    // Error checking
    if (r_en && w_en) begin
        state <= `MEMORY_STATE_READ_WRITE;
//        $display("mem read and write at the same time");
    end else if ((r_en) && (r_addr_wrd >= MEMORY_SIZE_WORDS)) begin
        state <= `MEMORY_STATE_OUT_OF_BOUNDS;
//        $display("mem %s read out of bounds at [%08h]", NAME, r_addr);
    end else if ((w_en) && (w_addr_wrd >= MEMORY_SIZE_WORDS)) begin
        state <= `MEMORY_STATE_OUT_OF_BOUNDS;
//        $display("mem %s write out of bounds at [%08h]", NAME, w_addr);
    end
//    end else if ((r_en) && (r_addr_offset != 2'b00)) begin
//        state <= `MEMORY_STATE_ALIGNMENT;
////        $display("mem %s read unaligned at [%08h]", NAME, r_addr);
//    end else if ((w_en) && (w_addr_offset != 2'b00)) begin
//        state <= `MEMORY_STATE_ALIGNMENT;
////        $display("mem %s write unaligned at [%08h]", NAME, w_addr);
//    end
    
    // Memory operations
    else if (w_en) begin
        for (i=0;i<4;i=i+1) begin
            if (w_strb[i]) mem[w_addr_wrd][i*8+:8] <= w_data_align[i*8+:8];
        end
        state <= `MEMORY_STATE_SUCCESS;
    end
    else if (r_en) begin
        r_data_unalign <= mem[r_addr_wrd];
        state <= `MEMORY_STATE_SUCCESS;
    end
end

initial begin
    state <= `MEMORY_STATE_SUCCESS;
    if (INIT_FILE != "") begin
        $readmemh(INIT_FILE, mem);
    end
end

endmodule
