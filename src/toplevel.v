`timescale 1ns / 1ps

module toplevel(
    input       GLOBAL_CLK_IN,
    input       GLOBAL_RST_N
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
wire    [2:0]   dbg_state;
wire    [31:0]  dbg_pc;
wire    [31:0]  dbg_instr;
wire    [(32*32)-1:0] dbg_reg_data;

memory mem_data(
    .clk(GLOBAL_CLK_IN),
    .r_en(mem_data_r_en),
    .r_addr(mem_data_r_addr),
    .r_data(mem_data_r_data),
    .w_en(mem_data_w_en),
    .w_addr(mem_data_w_addr),
    .w_data(mem_data_w_data)
);

memory mem_instr(
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
    .dbg_state(dbg_state),
    .dbg_pc(dbg_pc),
    .dbg_instr(dbg_instr),
    .dbg_reg_data(dbg_reg_data)
);



endmodule