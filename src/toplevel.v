`timescale 1ns / 1ps

module toplevel #(
    parameter DATA_INIT_FILE        = "",
    parameter INSTR_INIT_FILE       = ""
) (
    input               sysclk,
    input               btnrst,
    input               btntrig,
    input               uartin,
    output              uartout,
    output              led0,
    output              led1,
    output              led2,
    output              led3,
    input   [3:0]       jb_sel,
    output  [3:0]       jb_state,
    output  [7:0]       aout
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
//assign led0 = trig;

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

wire            bus_r_en;
wire    [31:0]  bus_r_addr;
wire    [31:0]  bus_r_data;
wire            bus_w_en;
wire    [31:0]  bus_w_addr;
wire    [31:0]  bus_w_data;

wire            gpio_a_en;
wire    [31:0]  gpio_a_addr;

// Data memory bus
wire            mem_data_r_en;
wire    [31:0]  mem_data_r_addr;
wire    [31:0]  mem_data_r_data;
wire            mem_data_w_en;
wire    [31:0]  mem_data_w_addr;
wire            mem_data_busy;

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

busdev #(
    .BASE(28'h0000001),
    .OFFS(32'h00000010),
    .MASK(4)
) gpio_a_w (
    .n_rst(n_rst && cpuclklocked),
    .clk(cpuclk),
    .en(bus_w_en),
    .addr(bus_w_addr),
    .deven(gpio_a_en),
    .devaddr(gpio_a_addr),
    .busy()
);

busdev #(
    .BASE(20'h00001),
    .OFFS(32'h00001000),
    .MASK(12)
) mem_data_w (
    .n_rst(n_rst && cpuclklocked),
    .clk(cpuclk),
    .en(bus_w_en),
    .addr(bus_w_addr),
    .deven(mem_data_w_en),
    .devaddr(mem_data_w_addr),
    .busy()
);

busdev #(
    .BASE(20'h00001),
    .OFFS(32'h00001000),
    .MASK(12)
) mem_data_r (
    .n_rst(n_rst && cpuclklocked),
    .clk(cpuclk),
    .en(bus_r_en),
    .addr(bus_r_addr),
    .deven(mem_data_r_en),
    .devaddr(mem_data_r_addr),
    .busy() //    .busy(mem_data_busy)
);

gpio gpio_a (
    .clk(cpuclk),
    .w_en(gpio_a_en),
    .w_addr(gpio_a_addr),
    .w_data(bus_w_data),
    .out(aout)
);

memory #(
    .NAME("DATA"), 
    .INIT_FILE("init_data.mem")
) mem_data (
    .clk(cpuclk),
    .r_en(mem_data_r_en),
    .r_addr(mem_data_r_addr),
    .r_data(bus_r_data), // add devmux when attaching more than 1 device
    .w_en(mem_data_w_en),
    .w_addr(mem_data_w_addr),
    .w_data(bus_w_data),
    .state()
);

memory #(
    .NAME("PROG"), 
    .INIT_FILE("iotest.mem")
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
    .mem_instr_w_en(),
    .mem_instr_w_addr(),
    .mem_instr_w_data(),
    .mem_data_r_en(bus_r_en),
    .mem_data_r_addr(bus_r_addr),
    .mem_data_r_data(bus_r_data),
    .mem_data_w_en(bus_w_en),
    .mem_data_w_addr(bus_w_addr),
    .mem_data_w_data(bus_w_data),
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

wire uartdone;
wire [7:0] charout;

uarttx dbguarttx (
    .n_rst(n_rst && cpuclklocked),
    .clk(cpuclk),
    .charin(charin),
    .txen(uarttxen),
    .busy(uartbusy),
    .phytx(uartout)
);

uartrx ctluartrx (
    .n_rst(n_rst && cpuclklocked),
    .clk(cpuclk),
    .charout(charout),
    .done(uartdone),
    .busy(),
    .phyrx(uartin)
);

dbgtouart dbguart (
    .n_rst(n_rst && cpuclklocked),
    .clk(cpuclk),
    .trig(trig),
    .uartbusy(uartbusy),
    .busy(), // .busy(led1)
    .dbgsel(dbg_reg_sel),
    .dbgreaden(),
    .dbgout(dbg_reg_data),
    .charout(charin),
    .uarttxen(uarttxen)
);

uarttoctl ctluart (
    .n_rst(n_rst && cpuclklocked),
    .clk(cpuclk),
    .charin(charout),
    .uartdone(uartdone),
    .acklast(),
    .cpuhalt(led0),
    .cpustart(led1),
    .cpustep(led2),
    .cpurst(led3),
    .dvpage(),
    .pvpage(),
    .progen(mem_instr_w_en),
    .progaddr(mem_instr_w_addr),
    .progdata(mem_instr_w_data)
);

endmodule