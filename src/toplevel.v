`timescale 1ns / 1ps

module toplevel (
    input               SYS_CLK,        // System clock input
    input               BTN_RST,        // Button to reset the CPU (active high)
    input               BTN_TRIG,       // Button to trigger debug print (active high)
    input               DBG_UART_IN,    // Debug UART receive line
    output              DBG_UART_OUT,   // Debug UART transmit line
    output              LED0,           //  \
    output              LED1,           //  | LED indicators for CPU state
    output              LED2,           //  |
    output              LED3,           //  /
    input   [7:0]       GPIO0_IN,       // GPIO input
    output  [7:0]       GPIO0_OUT,      // GPIO output
    output  [4:0]       VID_R,           // VGA red
    output  [5:0]       VID_G,           // VGA green
    output  [4:0]       VID_B,           // VGA blue
    output              VID_HS,          // VGA hsync
    output              VID_VS           // VGA vsync
);

wire n_rst = !BTN_RST;
wire print_trig_btn;

debounce debouncet (
    .n_rst(n_rst && cpuclklocked),
    .clk(cpuclk),
    .in(BTN_TRIG),
    .out(print_trig_btn)
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
wire    [31:0]  dbg_reg_data;
wire     [4:0]  dbg_reg_sel;

wire            dbg_force_rst;

wire            dbg_trig_halt;
wire            dbg_trig_unhalt;
wire            dbg_trig_cycle;
wire            dbg_trig_step;
wire            dbg_suppress_clock;

/********************************
 *   CLOCK GENERATION AND CMU   *
 ********************************/

wire            cpuclk;         // MCU clock
wire            cpuclklocked;   // MCU clock locked signal (PLL in sync)
wire            vgaclk;         // VGA clock
wire            vgaclklocked;   // VGA clock locked signal (PLL in sync)

// CLOCK DOWNSCALERS
prescaler #(
    .FMUL(5.0),
    .CDIV(125)
) prescalercpu (
    .n_rst(n_rst),
    .clkin(SYS_CLK),
    .clkout(cpuclk),
    .locked(cpuclklocked)
);

prescaler #(
    .FMUL(8.0),
    .CDIV(25)
) prescalervga (
    .n_rst(n_rst),
    .clkin(SYS_CLK),
    .clkout(vgaclk),
    .locked(vgaclklocked)
);

// CLOCK MANAGEMENT UNIT
wire            cycle_end;
wire            clk_enable;
wire            cpu_breakpoint;

cmu cmu1 (
    .clk_in(cpuclk),
    .rst_n(n_rst && cpuclklocked),
    .trig_halt(dbg_trig_halt || cpubreak),
    .clock_supress(dbg_suppress_clock),
    .trig_unhalt(dbg_trig_unhalt),
    .trig_cycle(dbg_trig_cycle),
    .trig_step(dbg_trig_step),
    .cycle_end(cycle_end),
    .clk_enable(clk_enable),
    .debug_trig()
);

/********************************
 *           MCU CORE           *
 ********************************/

wire    [3:0] cpu_state;

assign LED0 = cpu_state[0];
assign LED1 = cpu_state[1];
assign LED2 = cpu_state[2];
assign LED3 = cpu_state[3];

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
    .dbg_reg_data(dbg_reg_data),
    .dbg_reg_sel(dbg_reg_sel)
);

// Instruction memory
memory #(
    .MEMORY_SIZE_WORDS(1024),       // 4KB
    .INIT_FILE("init_instr_spin.mem")
) mem_instr (
    .clk(cpuclk),
    .rst_n(n_rst && cpuclklocked),
    .clk_enable(1'b1),              // Instruction memory always enabled to allow programming
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
wire            mem_data_r_sel;

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
    .sel()
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
    .sel(mem_data_r_sel)
);

memory_ba #(
    .MEMORY_SIZE_WORDS(1024),       // 4KB
    .INIT_FILE("init_data_clear.mem")
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
wire            gpio0_r_sel;

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
    .sel()
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
    .sel(gpio0_r_sel)
);

gpio gpio0 (
    .clk(cpuclk),
    .wen(gpio0_w_en),
    .wdata(bus_w_data[7:0]),
    .ren(gpio0_r_en),
    .rdata(gpio0_r_data),
    .phyin(GPIO0_IN),
    .phyout(GPIO0_OUT)
);

// Timer device
wire            tim0_r_sel;

wire            tim0_r_en;
wire     [7:0]  tim0_r_data;
wire            tim0_w_en;

busdev #(
    .BASE(28'h0000002),
    .OFFS(32'h00000020),
    .MASK(4)
) tim0_w (
    .en(bus_w_en),
    .addr(bus_w_addr),
    .deven(tim0_w_en),
    .devaddr(),
    .sel()
);

busdev #(
    .BASE(28'h0000002),
    .OFFS(32'h00000020),
    .MASK(4)
) tim0_r (
    .en(bus_r_en),
    .addr(bus_r_addr),
    .deven(tim0_r_en),
    .devaddr(),
    .sel(tim0_r_sel)
);

timer tim0 (
    .clk(cpuclk),
    .n_rst(n_rst && cpuclklocked),
    .bus_r_en(tim0_r_en),
    .bus_r_addr(bus_r_addr),
    .bus_r_data(tim0_r_data),
    .bus_w_en(tim0_w_en),
    .bus_w_addr(bus_w_addr),
    .bus_w_data(bus_w_data)
);

// Terminal device
wire            vidlm;
wire            term0_deven;
wire    [31:0]  term0_devaddr;

busdev #(
    .BASE(28'h0000005),
    .OFFS(32'h00000050),
    .MASK(4)
) term0_w (
    .en(bus_w_en),
    .addr(bus_w_addr),
    .deven(term0_deven),
    .devaddr(term0_devaddr),
    .sel()
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
    .vidhs(VID_HS),
    .vidvs(VID_VS)
);

assign VID_R = {5{vidlm}};
assign VID_G = {6{vidlm}};
assign VID_B = {5{vidlm}};

// Multiplex data bus read
assign bus_r_data = mem_data_r_sel  ? mem_data_r_data       :
                    tim0_r_sel      ? {24'b0, tim0_r_data}  :
                    gpio0_r_sel     ? {24'b0, gpio0_r_data} :
                    32'b0;

/********************************
 *        DEBUG INTERFACE       *
 ********************************/

dbgtoplevel dbgtop (
    .n_rst(n_rst && cpuclklocked),
    .clk(cpuclk),
    .btn_trig(dbg_trig_btn),
    .cpu_rst(dbg_force_rst),
    .reg_sel(dbg_reg_sel),
    .reg_data(dbg_reg_data),
    .cmu_trig_halt(dbg_trig_halt),
    .cmu_trig_unhalt(dbg_trig_unhalt),
    .cmu_trig_step(dbg_trig_step),
    .cmu_trig_cycle(dbg_trig_cycle),
    .cmu_suppress_clock(dbg_suppress_clock),
    .prog_w_en(mem_instr_w_en),
    .prog_w_addr(mem_instr_w_addr),
    .prog_w_data(mem_instr_w_data),
    .uart_out(DBG_UART_OUT),
    .uart_in(DBG_UART_IN)
);

endmodule