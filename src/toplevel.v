`timescale 1ns / 1ps

module toplevel #(
    parameter DATA_INIT_FILE        = "",
    parameter INSTR_INIT_FILE       = ""
) (
    input               sysclk,
    input               btnrst,
    input               btntrig,
    output              led0,
    output              led1,
    output              uartout,
    input   [3:0]       jb_sel,
    output  [3:0]       jb_state
);

wire n_rst = !btnrst;

// clock downscaler
wire cpuclk;
wire cpuclklocked;

prescaler #(
    .FMUL(40.0),
    .FDIV(5),
    .CDIV(125)
) prescalercpu (
    .n_rst(n_rst),
    .clkin(sysclk),
    .clkout(cpuclk),
    .locked(cpuclklocked)
);

wire trig;
assign led0 = trig;

debounce debouncet (
    .n_rst(n_rst && cpuclklocked),
    .clk(cpuclk),
    .in(btntrig),
    .out(trig)
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

//data_bus main_bus (
//    .clk(cpuclk),
//    .r_en(mem_data_r_en),
//    .r_addr(mem_data_r_addr),
//    .r_data(mem_data_r_data),
//    .w_en(mem_data_w_en),
//    .w_addr(mem_data_w_addr),
//    .w_data(mem_data_w_data)
//);

memory #(
    .NAME("DATA"), 
    .INIT_FILE("init_data.mem")
) mem_data (
    .clk(cpuclk),
    .r_en(mem_data_r_en),
    .r_addr(mem_data_r_addr),
    .r_data(mem_data_r_data),
    .w_en(mem_data_w_en),
    .w_addr(mem_data_w_addr),
    .w_data(mem_data_w_data),
    .state()
);

memory #(
    .NAME("PROG"), 
    .INIT_FILE("init_prog_cafe.mem")
) mem_instr (
    .clk(cpuclk),
    .r_en(mem_instr_r_en),
    .r_addr(mem_instr_r_addr),
    .r_data(mem_instr_r_data),
    .w_en(mem_instr_w_en),
    .w_addr(mem_instr_w_addr),
    .w_data(mem_instr_w_data),
    .state()
);

core cpu1 (
    .clk(cpuclk),
    .rst_n(n_rst && cpuclklocked),
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
    .dbg_reg_sel(dbg_reg_sel),
    .clk_enable(),
    .cycle_end()
);

wire uartbusy;
wire uarttxen;
wire [7:0] charin;

uarttx dbguarttx (
    .n_rst(n_rst && cpuclklocked),
    .clk(cpuclk),
    .charin(charin),
    .txen(uarttxen),
    .busy(uartbusy),
    .phytx(uartout)
);

dbgtouart dbguartctl (
    .n_rst(n_rst && cpuclklocked),
    .dbgclk(cpuclk),
    .trig(trig),
    .uartbusy(uartbusy),
    .busy(led1),
    .dbgsel(dbg_reg_sel),
    .dbgreaden(),
    .dbgout(dbg_reg_data),
    .charout(charin),
    .uarttxen(uarttxen)
);


endmodule