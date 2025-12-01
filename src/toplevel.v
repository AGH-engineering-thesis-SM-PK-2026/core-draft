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
    .FDIV(8),
    .CDIV(125)
) prescalercpu (
    .n_rst(n_rst),
    .clkin(sysclk),
    .clkout(cpuclk),
    .locked(cpuclklocked)
);

wire btnprint;
wire uartprint;
wire printbusy;

debounce debouncet (
    .n_rst(n_rst && cpuclklocked),
    .clk(cpuclk),
    .in(btntrig),
    .out(btnprint)
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
wire    [31:0]  dbg_reg_out;
wire    [31:0]  dbg_out;
wire    [5:0]   dbg_sel;

wire clk_enable;
wire cycle_end;

wire cpuhalt;
wire cpustart;
wire cpustep;
wire cpucycle;
wire cpurst;
wire freeze;

cmu cmu1 (
    .clk_in(cpuclk),
    .rst_n(n_rst && cpuclklocked),
    .trig_halt(cpuhalt),
    .trig_unhalt(cpustart),
    .trig_cycle(cpucycle),
    .trig_step(cpustep),
    .freeze(freeze || printbusy),
    .cycle_end(cycle_end),
    .clk_enable(clk_enable),
    .debug_trig()
);

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

wire dbg_read_en;
wire cpu_data_r_en;
wire [31:0] cpu_data_r_addr;

busdev #(
    .BASE(20'h00001),
    .OFFS(32'h00001000),
    .MASK(12)
) mem_data_r (
    .n_rst(n_rst && cpuclklocked),
    .clk(cpuclk),
    .en(bus_r_en),
    .addr(bus_r_addr),
    .deven(cpu_data_r_en),
    .devaddr(cpu_data_r_addr),
    .busy() //    .busy(mem_data_busy)
);

assign mem_data_r_en = cpu_data_r_en || dbg_read_en;
assign mem_data_r_addr = !printbusy ? cpu_data_r_addr : 12'hffc;

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
    .INIT_FILE("init_void.mem")
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

wire [3:0] dbg_state;
assign led0 = dbg_state[0];
assign led1 = dbg_state[1];
assign led2 = dbg_state[2];
//assign led3 = dbg_state[3];

core cpu1 (
    .clk(cpuclk),
    .rst_n(n_rst && cpuclklocked && !cpurst),
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
    .dbg_state(dbg_state),    
    .dbg_data(dbg_reg_out),
    .dbg_sel(dbg_sel[4:0]),
    .clk_enable(clk_enable),
    .cycle_end(cycle_end)
);

wire uartbusy;
wire uarttxen;
wire [7:0] charin;

wire uartdone;
wire [7:0] charout;

uarttx #(
    .PREDIV(520) // 9600bps @ f=5MHz
) dbguarttx (
    .n_rst(n_rst && cpuclklocked),
    .clk(cpuclk),
    .charin(charin),
    .txen(uarttxen),
    .busy(uartbusy),
    .phytx(uartout)
);

uartrx #(
    .PREDIV(520), // 9600bps @ f=5MHz
    .PREMID(250)  // midpoint for sampling
) ctluartrx (
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
    .trig(btnprint || uartprint),
    .uartbusy(uartbusy),
    .busy(printbusy),
    .dbgsel(dbg_sel),
    .dbgreaden(dbg_read_en),
    .dbgout(dbg_out),
    .charout(charin),
    .uarttxen(uarttxen)
);

wire [7:0] dbg_mem_page;

uarttoctl ctluart (
    .n_rst(n_rst && cpuclklocked),
    .clk(cpuclk),
    .charin(charout),
    .uartdone(uartdone),
    .cpuhalt(cpuhalt),
    .cpustart(cpustart),
    .cpustep(cpustep),
    .cpucycle(cpucycle),
    .cpurst(cpurst),
    .cpuprint(uartprint),
    .freeze(freeze),
    .dvpage(dbg_mem_page),
    .pvpage(),
    .progen(mem_instr_w_en),
    .progaddr(mem_instr_w_addr),
    .progdata(mem_instr_w_data)
);

dbgsel dbgsrcsel (
    .selregmem(dbg_sel[5]),
    .dbgreaden(dbg_read_en),
    .regin(dbg_reg_out),
    .datain(bus_r_data),
    .dbgout(dbg_out)
);

endmodule