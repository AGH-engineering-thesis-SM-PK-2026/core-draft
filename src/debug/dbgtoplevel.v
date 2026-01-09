
module dbgtoplevel (
    input           n_rst,
    input           clk,

    input           btn_trig,               // button to trigger debug print

    output          cpu_rst,                // debug-triggered CPU reset (active high)
    output   [4:0]  reg_sel,                // select register to read for debug UART
    input   [31:0]  reg_data,               // data from selected register

    output          cmu_trig_halt,          // debug-triggered CPU halt
    output          cmu_trig_unhalt,        // debug-triggered CPU start
    output          cmu_trig_step,          // debug-triggered CPU step
    output          cmu_trig_cycle,         // debug-triggered CPU cycle
    output          cmu_suppress_clock,     // debug module busy, suppress CPU clock

    output          prog_w_en,              // program memory write enable
    output  [31:0]  prog_w_addr,            // program memory write address
    output  [31:0]  prog_w_data,            // program memory write data

    output          uart_out,               // UART transmit line
    input           uart_in                 // UART receive line
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
    .n_rst(n_rst),
    .clk(clk),
    .charin(charin),
    .txen(uarttxen),
    .busy(uartbusy),
    .phytx(uart_out)
);

uartrx #(
    .PREDIV(520), // 9600bps @ f=5MHz
    .PREMID(250)  // midpoint for sampling
) ctluartrx (
    .n_rst(n_rst),
    .clk(clk),
    .charout(charout),
    .done(uartdone),
    .busy(),
    .phyrx(uart_in)
);

dbgtouart dbguart (
    .n_rst(n_rst),
    .clk(clk),
    .trig(btn_trig || uartprint),
    .uartbusy(uartbusy),
    .busy(printbusy),
    .dbgsel(reg_sel),
    .dbgreaden(),
    .dbgout(reg_data),
    .charout(charin),
    .uarttxen(uarttxen)
);

wire ctluart_freeze;

uarttoctl ctluart (
    .n_rst(n_rst),
    .clk(clk),
    .charin(charout),
    .uartdone(uartdone),
    .cpuhalt(cmu_trig_halt),
    .cpustart(cmu_trig_unhalt),
    .cpustep(cmu_trig_step),
    .cpucycle(cmu_trig_cycle),
    .cpurst(cpu_rst),
    .cpuprint(uartprint),
    .freeze(ctluart_freeze),
    .dvpage(),
    .pvpage(),
    .progen(prog_w_en),
    .progaddr(prog_w_addr),
    .progdata(prog_w_data)
);

assign cmu_suppress_clock = ctluart_freeze || printbusy;

endmodule