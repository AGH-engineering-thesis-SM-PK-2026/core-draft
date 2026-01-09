`timescale 1ns / 1ps
/*****************************************************************************
 *  Author: Piotr Kadziela
 *  Description:
 *      Basic BRAM-based, word-addressable memory module for RISC-V core.
 *      Only 32-bit word aligned access is supported. Strobe writes are 
 *      supported.
 *      Only one read or write operation is allowed at a time.
 *****************************************************************************/

`include "memory_states.vh"

module memory #(
    parameter NAME              = "",
    parameter MEMORY_SIZE_WORDS = 1024,                         // Memory size in 32-bit words
    parameter INIT_FILE         = "",                           // Path to memory initialization file. Zero-initialized if none is provided.
    parameter ADDR_WIDTH        = $clog2(MEMORY_SIZE_WORDS*4)   // Memory bus size. By default, the size needed to address MEMORY_SIZE_WORDS.
) (
    input               clk,
    input               rst_n,
    input               clk_enable,

    input               r_en,       // read enable
    input       [31:0]  r_addr,     // 32-bit address
    output reg  [31:0]  r_data,     // 32-bits of data

    input               w_en,       // write enable
    input       [31:0]  w_addr,     // 32-bit address
    input       [31:0]  w_data,     // 32-bits of data
    input       [3:0]   w_strb,     // write strobe - which bytes are to be written

    output reg  [1:0]   state       // memory state (error codes)
);

(* ram_style = "block" *)
reg     [31:0]  mem [0:MEMORY_SIZE_WORDS-1];


wire    [29:0]  r_addr_wrd;
wire    [1:0]   r_addr_offset;
wire    [29:0]  w_addr_wrd;
wire    [1:0]   w_addr_offset;

assign r_addr_wrd       = r_addr[ADDR_WIDTH-1:2];
assign r_addr_offset    = r_addr[1:0];
assign w_addr_wrd       = w_addr[ADDR_WIDTH-1:2];
assign w_addr_offset    = w_addr[1:0];

always @(posedge clk) begin
    if (!rst_n) begin
        state <= `MEMORY_STATE_SUCCESS;
    end else if ((r_en) && (r_addr_wrd >= MEMORY_SIZE_WORDS)) begin
        state <= `MEMORY_STATE_OUT_OF_BOUNDS;
    end else if ((w_en) && (w_addr_wrd >= MEMORY_SIZE_WORDS)) begin
        state <= `MEMORY_STATE_OUT_OF_BOUNDS;
    end else if ((r_en) && (r_addr_offset != 2'b00)) begin
        state <= `MEMORY_STATE_ALIGNMENT;
    end else if ((w_en) && (w_addr_offset != 2'b00)) begin
        state <= `MEMORY_STATE_ALIGNMENT;
    end
end

always @(posedge clk) begin
    if (!rst_n) begin
        r_data <= 32'b0;
    end
    else if (clk_enable) begin
        // Error checking
        if (w_en) begin
            if(w_strb[0]) mem[w_addr_wrd][7:0] <= w_data[7:0];
            if(w_strb[1]) mem[w_addr_wrd][15:8] <= w_data[15:8];
            if(w_strb[2]) mem[w_addr_wrd][23:16] <= w_data[23:16];
            if(w_strb[3]) mem[w_addr_wrd][31:24] <= w_data[31:24];
        end
        else if (r_en) begin
            r_data <= mem[r_addr_wrd];
        end
    end
end

initial begin
    if (INIT_FILE != "") begin
        $readmemh(INIT_FILE, mem);
    end
end

endmodule
