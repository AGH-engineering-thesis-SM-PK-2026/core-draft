/*****************************************************************************
 *  Author: Piotr Kadziela
 *  Description:
 *      Byte-addressable memory module for RISC-V core.
 *      This module serves as an interface between the MCU core and a 
 *      word-addressable memory module, handling byte-level addressing and 
 *      write strobes.
 *****************************************************************************/

`include "memory_states.vh"

module memory_ba #(
    parameter MEMORY_SIZE_WORDS = 1024,                         // Memory size in 32-bit words
    parameter INIT_FILE         = ""                            // Path to memory initialization file. Zero-initialized if none is provided.
) (
    input               clk,
    input               rst_n,
    input               clk_enable,

    input               r_en,       // read enable
    input       [31:0]  r_addr,     // 32-bit address
    output reg  [31:0]  r_data,     // 32-bits of data
    input        [1:0]  r_mode,     // read mode - byte (0'b00), half-word (0'b01), word (0'b10)

    input               w_en,       // write enable
    input       [31:0]  w_addr,     // 32-bit address
    input       [31:0]  w_data,     // 32-bits of data
    input        [1:0]  w_mode,     // write mode - byte (0'b00), half-word (0'b01), word (0'b10)

    output       [1:0]  state       // memory state (error codes)
);

wire    [31:0]  r_data_word;
wire    [31:0]  w_data_aligned;
reg      [3:0]  w_strb;
reg             error_flag;

memory #(
    .MEMORY_SIZE_WORDS(MEMORY_SIZE_WORDS),
    .INIT_FILE(INIT_FILE)
) mem_wa (
    .clk(clk),
    .rst_n(rst_n),
    .clk_enable(clk_enable),

    .r_en(r_en),
    .r_addr(r_addr & 32'hFFFFFFFC), // Align address to word boundary
    .r_data(r_data_word),

    .w_en(w_en),
    .w_addr(w_addr & 32'hFFFFFFFC), // Align address to word boundary
    .w_data(w_data_aligned),
    .w_strb(w_strb),

    .state()
);

assign state = error_flag ? `MEMORY_STATE_ALIGNMENT : mem_wa.state;

wire    [1:0]  r_addr_offset;
wire    [1:0]  w_addr_offset;

assign r_addr_offset = r_addr[1:0];
assign w_addr_offset = w_addr[1:0];

// Error flag for misaligned accesses
always @(posedge clk) begin
    if (!rst_n)
        error_flag <= 1'b0;
    else if ((r_en && (r_mode == `MODE_SH) && (r_addr_offset[0] != 1'b0))   // Half-word read misalignment
          || (w_en && (w_mode == `MODE_SH) && (w_addr_offset[0] != 1'b0))   // Half-word write misalignment
          || (r_en && (r_mode == `MODE_SW) && (r_addr_offset != 2'b00))     // Word read misalignment
          || (w_en && (w_mode == `MODE_SW) && (w_addr_offset != 2'b00))     // Word write misalignment
        )
        error_flag <= 1'b1;
end

// Read data alignment
always @* begin
    case (r_mode)
        `MODE_SB: r_data = {24'b0, r_data_word[(r_addr_offset*8) +: 8]};   // Byte
        `MODE_SH: r_data = {16'b0, r_data_word[(r_addr_offset*8) +: 16]};  // Half-word
        `MODE_SW: r_data = r_data_word;                                    // Word
        default: r_data = 32'b0;
    endcase
end

// Write data alignment and strobe generation
assign w_data_aligned = w_data << (w_addr_offset * 8);
always @* begin
    case (w_mode)
        `MODE_SB: w_strb = 4'b0001 << w_addr_offset;            // Byte
        `MODE_SH: w_strb = 4'b0011 << (w_addr_offset & 2'b10);  // Half-word
        `MODE_SW: w_strb = 4'b1111;                             // Word
        default: w_strb = 4'b0000;
    endcase
end


endmodule