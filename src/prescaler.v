`timescale 1ns / 1ps

// Clock prescaler based on the MMCME2 instance.
// Zybo provides a 125MHz clock source.
// The FMUL and FDIV set the freq. multiplier and divider for the VCO:
// f_VCO = (FMUL/FDIV) * 125MHz
// The f_VCO has to stay between 600 and 1200 MHz.
// The final freq value can be obtained from this formula:
// f_OUT = (1/CDIV) * f_VCO
// The MMCME2 needs some time to stabilise - locked output pin will
// transition to high when the clock source becomes stable.
// Szymon Miękina - 16.10.2025

module prescaler #(
    FMUL = 40.0,    // VCO freq. mult.
    FDIV = 1,       // VCO freq. div.
    CDIV = 25       // clock freq. div.
) (
    input wire  n_rst,
    input wire  clkin,  // system clock input
    output wire clkout, // clock signal output
    output reg  locked  // is clock ready to be used
);

wire feedback;
wire clkout_unbuf;
wire locked_unsync;

MMCME2_BASE #(
    .CLKFBOUT_MULT_F(FMUL),
    .DIVCLK_DIVIDE(FDIV),
    .CLKIN1_PERIOD(8.0),
    .CLKOUT1_DIVIDE(CDIV)
) MMCME2_BASE_inst (
    .CLKIN1(clkin),
    .RST(!n_rst),
    .CLKOUT1(clkout_unbuf),
    .LOCKED(locked_unsync),
    .CLKFBOUT(feedback),
    .CLKFBIN(feedback),
    .CLKOUT0(),
    .CLKOUT0B(),
    .CLKOUT1B(),
    .CLKOUT2(),
    .CLKOUT2B(),
    .CLKOUT3(),
    .CLKOUT3B(),
    .CLKOUT4(),
    .CLKOUT5(),
    .CLKOUT6(),
    .CLKFBOUTB(),
    .PWRDWN()
);

BUFG bufg_clkout (
    .I(clkout_unbuf), 
    .O(clkout)
);

reg locked_sync;

always @(posedge clkout) begin
    locked_sync <= locked_unsync;
    locked <= locked_sync;
    if (!n_rst) begin 
        locked <= 1'b0;
        locked_sync <= 1'b0;
    end
end

endmodule
