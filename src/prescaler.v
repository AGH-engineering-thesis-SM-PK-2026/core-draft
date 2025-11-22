`timescale 1ns / 1ps

// TODO
// Szymon Miękina - 16.10.2025

module prescaler #(
    FMUL = 40.0,
    FDIV = 5,
    CDIV = 25
) (
    input wire n_rst,
    input wire clkin,
    output wire clkout,
    output reg locked
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
