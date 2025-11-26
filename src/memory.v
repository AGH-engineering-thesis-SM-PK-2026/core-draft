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
// - rethink error handling (move to memory controller?)

`define MEMORY_STATE_SUCCESS        2'b00   // No error
`define MEMORY_STATE_READ_WRITE     2'b01   // Simultaneous read and write error
`define MEMORY_STATE_OUT_OF_BOUNDS  2'b10   // Address out-of-bounds error
`define MEMORY_STATE_ALIGNMENT      2'b11   // Aliginment error

module memory #(
    parameter NAME              = "",
    parameter MEMORY_SIZE_WORDS = 1024,                     // Memory size in 32-bit words
    parameter INIT_FILE         = "",                       // Path to memory initialization file. Zero-initialized if none is provided.
    parameter ADDR_WIDTH        = $clog2(MEMORY_SIZE_WORDS) // Memory bus size. By default, the size needed to address MEMORY_SIZE_WORDS.
) (
    input               clk,
    input               clk_enable,

    input               r_en,       // read enable
    input       [31:0]  r_addr,     // 32-bit address
    output reg  [31:0]  r_data,     // 32-bits of data

    input               w_en,       // write enable
    input       [31:0]  w_addr,     // 32-bit address
    input       [31:0]  w_data,     // 32-bits of data
    input       [4:0]   w_strb,     // write strobe - which bytes are to be written

    output reg  [1:0]   state       // memory state (error codes)
);

(* ram_style = "block" *)
reg     [31:0]  mem [0:MEMORY_SIZE_WORDS-1];


wire    [29:0]  r_addr_wrd;
wire    [1:0]   r_addr_offset;
wire    [29:0]  w_addr_wrd;
wire    [1:0]   w_addr_offset;

assign r_addr_wrd       = r_addr[ADDR_WIDTH:2];
assign r_addr_offset    = r_addr[1:0];
assign w_addr_wrd       = w_addr[ADDR_WIDTH:2];
assign w_addr_offset    = w_addr[1:0];

always @(posedge clk) begin
    if (!clk_enable) begin
        // Do nothing when core is halted
    end
    else begin
        // Error checking
        if (r_en && w_en) begin
            state <= `MEMORY_STATE_READ_WRITE;
            $display("mem read and write at the same time");
        end else if ((r_en) && (r_addr_wrd >= MEMORY_SIZE_WORDS)) begin
            state <= `MEMORY_STATE_OUT_OF_BOUNDS;
            $display("mem %s read out of bounds at [%08h]", NAME, r_addr);
        end else if ((w_en) && (w_addr_wrd >= MEMORY_SIZE_WORDS)) begin
            state <= `MEMORY_STATE_OUT_OF_BOUNDS;
            $display("mem %s write out of bounds at [%08h]", NAME, w_addr);
        end else if ((r_en) && (r_addr_offset != 2'b00)) begin
            state <= `MEMORY_STATE_ALIGNMENT;
            $display("mem %s read unaligned at [%08h]", NAME, r_addr);
        end else if ((w_en) && (w_addr_offset != 2'b00)) begin
            state <= `MEMORY_STATE_ALIGNMENT;
            $display("mem %s write unaligned at [%08h]", NAME, w_addr);
        end

        // Memory operations
        else if (w_en) begin
            mem[w_addr_wrd] <= (w_strb[0] ? w_data[7:0]   : mem[w_addr_wrd][7:0])   |
                            (w_strb[1] ? w_data[15:8]  : mem[w_addr_wrd][15:8])  |
                            (w_strb[2] ? w_data[23:16] : mem[w_addr_wrd][23:16]) |
                            (w_strb[3] ? w_data[31:24] : mem[w_addr_wrd][31:24]);
            state <= `MEMORY_STATE_SUCCESS;
            $strobe("mem %s write %0h at [%08h]", NAME, w_data, w_addr);
        end
        else if (r_en) begin
            r_data <= mem[r_addr_wrd];
            state <= `MEMORY_STATE_SUCCESS;
            $strobe("mem %s read %0h at [%08h]", NAME, r_data, r_addr);
        end
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

integer j;
initial begin
    #100000;
    for (j = 0; j < 32; j = j + 8)
        $display("%08x %08x %08x %08x  %08x %08x %08x %08x", mem[0+j], mem[1+j], mem[2+j], mem[3+j], mem[4+j], mem[5+j], mem[6+j], mem[7+j]);
    
end

endmodule
