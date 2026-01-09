
module dbgtoplevel (
    input           n_rst,
    input           cpuclk,
    input           cpuclklocked,

    input           print_trig_btn,         // button to trigger debug print

    output          dbg_force_rst,          // debug-triggered CPU reset (active high)
    output   [4:0]  dbg_reg_sel,            // select register to read for debug UART
    input   [31:0]  dbg_reg_data,           // data from selected register

    output          dbg_trig_halt,          // debug-triggered CPU halt
    output          dbg_trig_unhalt,        // debug-triggered CPU start
    output          dbg_trig_step,          // debug-triggered CPU step
    output          dbg_trig_cycle,         // debug-triggered CPU cycle
    output          dbg_suppress_clock,     // debug module busy, suppress CPU clock

    output          mem_instr_w_en,         // program memory write enable
    output  [31:0]  mem_instr_w_addr,       // program memory write address
    output  [31:0]  mem_instr_w_data,       // program memory write data

    output          uartout,                // UART transmit line
    input           uartin                  // UART receive line
);

wire printbusy;
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
    .trig(print_trig_btn || uartprint),
    .uartbusy(uartbusy),
    .busy(printbusy),
    .dbgsel(dbg_reg_sel),
    .dbgreaden(),
    .dbgout(dbg_reg_data),
    .charout(charin),
    .uarttxen(uarttxen)
);

wire ctluart_freeze;

uarttoctl ctluart (
    .n_rst(n_rst && cpuclklocked),
    .clk(cpuclk),
    .charin(charout),
    .uartdone(uartdone),
    .cpuhalt(dbg_trig_halt),
    .cpustart(dbg_trig_unhalt),
    .cpustep(dbg_trig_step),
    .cpucycle(dbg_trig_cycle),
    .cpurst(dbg_force_rst),
    .cpuprint(uartprint),
    .freeze(ctluart_freeze),
    .dvpage(),
    .pvpage(),
    .progen(mem_instr_w_en),
    .progaddr(mem_instr_w_addr),
    .progdata(mem_instr_w_data)
);

assign dbg_suppress_clock = ctluart_freeze || printbusy;

endmodule