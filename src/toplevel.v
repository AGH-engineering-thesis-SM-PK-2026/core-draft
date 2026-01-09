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



wire btnprint;
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

// Data memory bus signals
wire            bus_r_en;
wire    [31:0]  bus_r_addr;
wire    [31:0]  bus_r_data;
wire     [1:0]  bus_r_mode;

wire            bus_w_en;
wire    [31:0]  bus_w_addr;
wire    [31:0]  bus_w_data;
wire     [1:0]  bus_w_mode;

wire     [1:0]  bus_state;


// Debug bus
wire    [31:0]  dbg_out;
wire     [4:0]  dbg_sel;

wire            cpubreak;
wire            cpuhalt;
wire            cpustart;
wire            cpustep;
wire            cpucycle;
wire            dbg_force_rst;
wire            dbg_force_halt;

/********************************
 *   CMU AND CLOCK GENERATION   *
 ********************************/
wire            clk_enable;     // If MCU core should be running
wire            cycle_end;      // High before entering new instruction cycle (WB or INIT stage)

wire            cpuclk;         // MCU clock
wire            cpuclklocked;   // MCU clock locked signal (PLL in sync)
wire            vgaclk;         // VGA clock
wire            vgaclklocked;   // VGA clock locked signal (PLL in sync)


cmu cmu1 (
    .clk_in(cpuclk),
    .rst_n(n_rst && cpuclklocked),
    .trig_halt(cpuhalt || cpubreak),
    .clock_supress(dbg_force_halt || printbusy),
    .trig_unhalt(cpustart),
    .trig_cycle(cpucycle),
    .trig_step(cpustep),
    .cycle_end(cycle_end),
    .clk_enable(clk_enable),
    .debug_trig()
);

// CLOCK DOWNSCALERS
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

/********************************
 *           MCU CORE           *
 ********************************/

wire    [3:0] cpu_state;

core cpu1 (
    .clk(cpuclk),
    .rst_n(n_rst && cpuclklocked && !dbg_force_rst),
    .clk_enable(clk_enable),
    .cycle_end(cycle_end),
    .breakpoint_hit(cpubreak),
    .state_out(cpu_state),
    .mem_instr_r_en(mem_instr_r_en),
    .mem_instr_r_addr(mem_instr_r_addr),
    .mem_instr_r_data(mem_instr_r_data),
    .mem_data_r_en(bus_r_en),
    .mem_data_r_addr(bus_r_addr),
    .mem_data_r_data(bus_r_data),
    .mem_data_r_mode(bus_r_mode),
    .mem_data_w_en(bus_w_en),
    .mem_data_w_addr(bus_w_addr),
    .mem_data_w_data(bus_w_data),
    .mem_data_w_mode(bus_w_mode),
    .mem_data_state(bus_state),
    .dbg_data(dbg_out),
    .dbg_sel(dbg_sel)
);

assign led0 = cpu_state[0];
assign led1 = cpu_state[1];
assign led2 = cpu_state[2];
assign led3 = cpu_state[3];

// Instruction memory

memory #(
    .MEMORY_SIZE_WORDS(1024),       // 4KB instruction memory
    .INIT_FILE("init_instr_3d.mem")
) mem_instr (
    .clk(cpuclk),
    .rst_n(n_rst && cpuclklocked),
    .clk_enable(1'b1),  // Instruction memory always enabled to allow programming
    .r_en(mem_instr_r_en),
    .r_addr(mem_instr_r_addr),
    .r_data(mem_instr_r_data),
    .w_en(mem_instr_w_en),
    .w_addr(mem_instr_w_addr),
    .w_data(mem_instr_w_data),
    .w_strb(4'b1111),
    .state()
);


/********************************
 *   DATA BUS AND PERIPHERALS   *
 ********************************/

// Data memory
wire            mem_data_r_en;
wire    [31:0]  mem_data_r_addr;
wire    [31:0]  mem_data_r_data;
wire            mem_data_w_en;
wire    [31:0]  mem_data_w_addr;

busdev #(
    .BASE(20'h00001),
    .OFFS(32'h00001000),
    .MASK(12)
) mem_data_w (
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
    .en(bus_r_en),
    .addr(bus_r_addr),
    .deven(mem_data_r_en),
    .devaddr(mem_data_r_addr),
    .busy(mem_data_busy)
);

memory_ba #(
    .MEMORY_SIZE_WORDS(1024),       // 4KB
    .INIT_FILE("init_data.mem")
) mem_data (
    .clk(cpuclk),
    .rst_n(n_rst && cpuclklocked),
    .clk_enable(clk_enable),
    .r_en(mem_data_r_en),
    .r_addr(mem_data_r_addr),
    .r_data(mem_data_r_data),
    .r_mode(bus_r_mode),
    .w_en(mem_data_w_en),
    .w_addr(mem_data_w_addr),
    .w_data(bus_w_data),
    .w_mode(bus_w_mode),
    .state(bus_state)
);

// GPIO device
wire            gpio0_r_en;
wire     [7:0]  gpio0_r_data;
wire            gpio0_w_en;

busdev #(
    .BASE(28'h0000001),
    .OFFS(32'h00000010),
    .MASK(4)
) gpio0_w (
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

// Terminal device
wire vidlm;

wire term0_deven;
wire [31:0] term0_devaddr;

busdev #(
    .BASE(28'h0000005),
    .OFFS(32'h00000050),
    .MASK(4)
) term0_w (
    .en(bus_w_en),
    .addr(bus_w_addr),
    .deven(term0_deven),
    .devaddr(term0_devaddr),
    .busy()
);

term term0 (
    .n_rst(n_rst && cpuclklocked && vgaclklocked),
    .cpuclk(cpuclk),
    .vgaclk(vgaclk),
    .addrin(term0_devaddr[3:2]),
    .datain(bus_w_data[7:0]),
    .inen(term0_deven),
    .busy(),
    .vidlm(vidlm),
    .vidhs(vidhs),
    .vidvs(vidvs)
);

assign vidr = {5{vidlm}};
assign vidg = {6{vidlm}};
assign vidb = {5{vidlm}};

// At any point, only one device should respond, that is ensured by busdev modules
assign bus_r_data = gpio0_r_data | mem_data_r_data;

/********************************
 *        DEBUG INTERFACE       *
 ********************************/

wire uartprint;

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
    .cpurst(dbg_force_rst),
    .cpuprint(uartprint),
    .freeze(dbg_force_halt),
    .dvpage(),
    .pvpage(),
    .progen(mem_instr_w_en),
    .progaddr(mem_instr_w_addr),
    .progdata(mem_instr_w_data)
);

endmodule