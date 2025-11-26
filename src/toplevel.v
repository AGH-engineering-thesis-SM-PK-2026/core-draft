`include "data_bus_mux.vh"
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
    
// Core instruction bus interface
wire            mem_instr_r_en;
wire    [31:0]  mem_instr_r_addr;
wire    [31:0]  mem_instr_r_data;
wire            mem_instr_w_en;
wire    [31:0]  mem_instr_w_addr;
wire    [31:0]  mem_instr_w_data;
wire    [3:0]   mem_instr_w_strb;

// Core data bus interface
wire            mem_data_r_en;
wire    [31:0]  mem_data_r_addr;
wire    [31:0]  mem_data_r_data;
wire            mem_data_w_en;
wire    [31:0]  mem_data_w_addr;
wire    [31:0]  mem_data_w_data;
wire    [3:0]   mem_data_w_strb;


// Debug bus
wire    [31:0]  dbg_pc;
wire    [31:0]  dbg_reg_data;
wire    [4:0]   dbg_reg_sel;

// CMU interface
wire    clk_enable;
wire    trigger_clock_halt;
wire    cmu_trig_debug;             // trigger from CMU to print debug info
wire    cmu_clock_supress;          // prevent unhalting when debug interface is busy

data_bus_mux data_bus1(         // 4 slaves: data mem, instr mem, 2 peripherals
    .core_r_en(mem_data_r_en),
    .core_r_addr(mem_data_r_addr),
    .core_r_data(mem_data_r_data),
    .core_w_en(mem_data_w_en),
    .core_w_addr(mem_data_w_addr),
    .core_w_data(mem_data_w_data),
    .core_w_strb(mem_data_w_strb),
    .bus_data_r_en(),
    .bus_data_r_addr(),
    .bus_data_r_data(),
    .bus_data_w_en(),
    .bus_data_w_addr(),
    .bus_data_w_data(),
    .bus_data_w_strb()
);

memory #(.NAME("DATA"), .INIT_FILE(DATA_INIT_FILE)) mem_data(
    .clk(GLOBAL_CLK_IN),
    .clk_enable(clk_enable),
    .r_en(data_bus1.bus_data_r_en[0]),
    .r_addr(data_bus1.bus_data_r_addr[`N_th_WORD_END(0):`N_th_WORD_BEGIN(0)]),
    .r_data(data_bus1.bus_data_r_data[`N_th_WORD_END(0):`N_th_WORD_BEGIN(0)]),
    .w_en(data_bus1.bus_data_w_en[0]),
    .w_addr(data_bus1.bus_data_w_addr[`N_th_WORD_END(0):`N_th_WORD_BEGIN(0)]),
    .w_data(data_bus1.bus_data_w_data[`N_th_WORD_END(0):`N_th_WORD_BEGIN(0)]),
    .w_strb(data_bus1.bus_data_w_strb[`N_th_STRB_END(0):`N_th_STRB_BEGIN(0)])
);

// Map instruction memory onto data address space
memory #(.NAME("PROG"), .INIT_FILE(INSTR_INIT_FILE)) mem_instr(
    .clk(GLOBAL_CLK_IN),
    .clk_enable(clk_enable),
    .r_en(mem_instr_r_en),
    .r_addr(mem_instr_r_addr),
    .r_data(mem_instr_r_data),
    .w_en(mem_instr_w_en),
    .w_addr(mem_instr_w_addr),
    .w_data(mem_instr_w_data),
    .w_strb(mem_instr_w_strb)
);

core cpu1(
    .clk(GLOBAL_CLK_IN),
    .rst_n(GLOBAL_RST_N),
    .clk_enable(clk_enable),
    .cycle_end(),
    .breakpoint_hit(),
    .mem_instr_r_en(mem_instr_r_en),
    .mem_instr_r_addr(mem_instr_r_addr),
    .mem_instr_r_data(mem_instr_r_data),
    .mem_instr_w_en(mem_instr_w_en),
    .mem_instr_w_addr(mem_instr_w_addr),
    .mem_instr_w_data(mem_instr_w_data),
    .mem_instr_w_strb(mem_instr_w_strb),
    .mem_data_r_en(mem_data_r_en),
    .mem_data_r_addr(mem_data_r_addr),
    .mem_data_r_data(mem_data_r_data),
    .mem_data_w_en(mem_data_w_en),
    .mem_data_w_addr(mem_data_w_addr),
    .mem_data_w_data(mem_data_w_data),
    .mem_data_w_strb(mem_data_w_strb),
    .dbg_state(jb_state),    
    .dbg_pc(dbg_pc),
    .dbg_reg_data(dbg_reg_data),
    .dbg_reg_sel(dbg_reg_sel)
);

// ON-BOARD BUTTONS

debouncer db_button_halt(
    .clk(GLOBAL_CLK_IN),
    .rst_n(GLOBAL_RST_N),
    .sw_in(jb_sel[0]),
    .sw_pulse()
);

debouncer db_button_unhalt(
    .clk(GLOBAL_CLK_IN),
    .rst_n(GLOBAL_RST_N),
    .sw_in(jb_sel[1]),
    .sw_pulse()
);

debouncer db_button_cycle(
    .clk(GLOBAL_CLK_IN),
    .rst_n(GLOBAL_RST_N),
    .sw_in(jb_sel[2]),
    .sw_pulse()
);

debouncer db_button_step(
    .clk(GLOBAL_CLK_IN),
    .rst_n(GLOBAL_RST_N),
    .sw_in(jb_sel[3]),
    .sw_pulse()
);

cmu cmu1(
    .clk_in(GLOBAL_CLK_IN),
    .rst_n(GLOBAL_RST_N),
    .cycle_end(cpu1.cycle_end),
    .trig_halt(trigger_clock_halt),
    .trig_unhalt(db_button_unhalt.sw_pulse),
    .trig_cycle(db_button_cycle.sw_pulse),
    .trig_step(db_button_step.sw_pulse),
    .clock_supress(cmu_clock_supress),
    .debug_trig(cmu_trig_debug),
    .clk_enable(clk_enable)
);

assign trigger_clock_halt = (db_button_halt.sw_pulse | cpu1.breakpoint_hit);

endmodule