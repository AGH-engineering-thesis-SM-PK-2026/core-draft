`timescale 1ns / 1ps

module toplevel #(
    parameter DATA_INIT_FILE        = "",
    parameter INSTR_INIT_FILE       = ""
) (
    input               GLOBAL_CLK_IN,
    input               GLOBAL_RST_N,
    input   [3:0]       jb_sel,
    output  [3:0]       jb_state
);

// Instruction memory bus
wire            mem_instr_r_en;
wire    [31:0]  mem_instr_r_addr;
wire    [31:0]  mem_instr_r_data;
wire            mem_instr_w_en;
wire    [31:0]  mem_instr_w_addr;
wire    [31:0]  mem_instr_w_data;

// Data memory bus
wire            mem_data_r_en;
wire    [31:0]  mem_data_r_addr;
wire    [31:0]  mem_data_r_data;
wire            mem_data_w_en;
wire    [31:0]  mem_data_w_addr;
wire    [31:0]  mem_data_w_data;

// Debug bus
wire    [31:0]  dbg_pc;
wire    [31:0]  dbg_reg_data;
wire    [4:0]   dbg_reg_sel;

memory #(.NAME("DATA"), .INIT_FILE(DATA_INIT_FILE)) mem_data(
    .clk(GLOBAL_CLK_IN),
    .r_en(mem_data_r_en),
    .r_addr(mem_data_r_addr),
    .r_data(mem_data_r_data),
    .w_en(mem_data_w_en),
    .w_addr(mem_data_w_addr),
    .w_data(mem_data_w_data)
 );

memory #(.NAME("PROG"), .INIT_FILE(INSTR_INIT_FILE)) mem_instr(
    .clk(GLOBAL_CLK_IN),
    .r_en(mem_instr_r_en),
    .r_addr(mem_instr_r_addr),
    .r_data(mem_instr_r_data),
    .w_en(mem_instr_w_en),
    .w_addr(mem_instr_w_addr),
    .w_data(mem_instr_w_data)
);

core cpu1(
    .clk(GLOBAL_CLK_IN),
    .rst_n(GLOBAL_RST_N),
    .mem_instr_r_en(mem_instr_r_en),
    .mem_instr_r_addr(mem_instr_r_addr),
    .mem_instr_r_data(mem_instr_r_data),
    .mem_instr_w_en(mem_instr_w_en),
    .mem_instr_w_addr(mem_instr_w_addr),
    .mem_instr_w_data(mem_instr_w_data),
    .mem_data_r_en(mem_data_r_en),
    .mem_data_r_addr(mem_data_r_addr),
    .mem_data_r_data(mem_data_r_data),
    .mem_data_w_en(mem_data_w_en),
    .mem_data_w_addr(mem_data_w_addr),
    .mem_data_w_data(mem_data_w_data),
    .dbg_state(jb_state),    
    .dbg_pc(dbg_pc),
    .dbg_reg_data(dbg_reg_data),
    .dbg_reg_sel(dbg_reg_sel)
);





endmodule