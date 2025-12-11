`timescale 1ns / 1ps

module toplevel (
    input               sysclk,
    input               btnrst,
    input               btntrig,
    input               uartin,
    output              uartout,
    output              led0,
    output              led1,
    output              led2,
    output              led3,
    input   [7:0]       in0,
    output  [7:0]       out0,
    output  [4:0]       vidr,
    output  [5:0]       vidg,
    output  [4:0]       vidb,
    output              vidhs,
    output              vidvs
);

wire n_rst = !btnrst;

// clock downscaler
wire cpuclk;
wire cpuclklocked;
wire vgaclk;
wire vgaclklocked;

prescaler #(
    .FMUL(5.0),
    .CDIV(125)
) prescalercpu (
    .n_rst(n_rst),
    .clkin(sysclk),
    .clkout(cpuclk),
    .locked(cpuclklocked)
);

prescaler #(
    .FMUL(8.0),
    .CDIV(25)
) prescalervga (
    .n_rst(n_rst),
    .clkin(sysclk),
    .clkout(vgaclk),
    .locked(vgaclklocked)
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
wire    [1:0]   bus_r_bmul;
wire            bus_w_en;
wire    [31:0]  bus_w_addr;
wire    [31:0]  bus_w_data;
wire    [1:0]   bus_w_bmul;

wire            gpio0_r_en;
wire            gpio0_w_en;
wire    [7:0]   gpio0_r_data;
wire    [7:0]   gpio0_w_data;

wire            term0_en;
wire    [3:0]   term0_addr;

// Data memory bus
wire            mem_data_r_en;
wire    [31:0]  mem_data_r_addr;
wire    [31:0]  mem_data_r_data;
wire            mem_data_w_en;
wire    [31:0]  mem_data_w_addr;
wire            mem_data_busy;

// Debug bus
wire    [31:0]  dbg_out;
wire    [4:0]   dbg_sel;

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
) gpio0_w (
    .n_rst(n_rst && cpuclklocked),
    .clk(cpuclk),
    .en(bus_w_en),
    .addr(bus_w_addr),
    .deven(gpio0_w_en),
    .devaddr(),
    .busy()
);

busdev #(
    .BASE(28'h0000001),
    .OFFS(32'h00000010),
    .MASK(4)
) gpio0_r (
    .n_rst(n_rst && cpuclklocked),
    .clk(cpuclk),
    .en(bus_r_en),
    .addr(bus_r_addr),
    .deven(gpio0_r_en),
    .devaddr(),
    .busy(gpio0_busy)
);

gpio gpio0 (
    .clk(cpuclk),
    .wen(gpio0_w_en),
    .wdata(bus_w_data[7:0]),
    .ren(gpio0_r_en),
    .rdata(gpio0_r_data),
    .phyin(in0),
    .phyout(out0)
);

busdev #(
    .BASE(28'h0000005),
    .OFFS(32'h00000050),
    .MASK(4)
) term0_w (
    .n_rst(n_rst && cpuclklocked),
    .clk(cpuclk),
    .en(bus_w_en),
    .addr(bus_w_addr),
    .deven(term0_en),
    .devaddr(term0_addr),
    .busy()
);

term term0 (
    .n_rst(n_rst && cpuclklocked && vgaclklocked),
    .cpuclk(cpuclk),
    .vgaclk(vgaclk),
    .addrin(term0_addr[3:2]),
    .datain(bus_w_data[7:0]),
    .inen(term0_en),
    .busy(),
    .vidlm(vidlm),
    .vidhs(vidhs),
    .vidvs(vidvs)
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
    .busy(mem_data_busy)
);

memory #(
    .NAME("DATA"), 
    .INIT_FILE("init_data.mem")
) mem_data (
    .clk(cpuclk),
    .r_en(mem_data_r_en),
    .r_addr(mem_data_r_addr),
    .r_data(mem_data_r_data),
    .r_bmul(bus_r_bmul),
    .w_en(mem_data_w_en),
    .w_addr(mem_data_w_addr),
    .w_data(bus_w_data),
    .w_bmul(bus_w_bmul),
    .state()
);

busmux2 r_mux (
    .busy1(gpio0_busy),
    .busy2(mem_data_busy),
    .src1({24'b0, gpio0_r_data}),
    .src2(mem_data_r_data),
    .out(bus_r_data)
);

memory #(
    .NAME("PROG"), 
    .INIT_FILE("init_empty.mem")
) mem_instr (
    .clk(cpuclk),
    .r_en(mem_instr_r_en),
    .r_addr(mem_instr_r_addr),
    .r_data(mem_instr_r_data),
    .r_bmul(),
    .w_en(mem_instr_w_en),
    .w_addr(mem_instr_w_addr),
    .w_data(mem_instr_w_data),
    .w_bmul(),
    .state()
);

wire [3:0] dbg_state;
assign led0 = dbg_state[0];
assign led1 = dbg_state[1];
assign led2 = dbg_state[2];
assign led3 = dbg_state[3];

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
    .mem_data_r_bmul(bus_r_bmul),
    .mem_data_w_en(bus_w_en),
    .mem_data_w_addr(bus_w_addr),
    .mem_data_w_data(bus_w_data),
    .mem_data_w_bmul(bus_w_bmul),
    .dbg_state(dbg_state),    
    .dbg_data(dbg_out),
    .dbg_sel(dbg_sel),
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
    .dbgreaden(),
    .dbgout(dbg_out),
    .charout(charin),
    .uarttxen(uarttxen)
);

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
    .dvpage(),
    .pvpage(),
    .progen(mem_instr_w_en),
    .progaddr(mem_instr_w_addr),
    .progdata(mem_instr_w_data)
);

assign vidr = {5{vidlm}};
assign vidg = {6{vidlm}};
assign vidb = {5{vidlm}};

endmodule