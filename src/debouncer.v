/*****************************************************************************
 *  Author: Piotr Kadziela
 *  Description:
 *      A generic debouncer module for mechanical switches. Uses internal 
 *      prescaler.
 *****************************************************************************/

module debouncer #(
    parameter PRESCALER_DIV       = 10000,                  // prescaler division factor (assuming clk is in kHz, 10000 = one sample for every 10ms)
    parameter PRESCALER_WIDTH     = $clog2(PRESCALER_DIV),
    parameter CONSECUTIVE_SAMPLES = 16                      // number of consecutive stable samples needed to change output state
) (
    input               clk,
    input               rst_n,

    input               sw_in,      // raw input from the mechanical switch
    output reg          sw_out,     // debounced output
    output reg          sw_pulse,   // debounced output (one clock pulse on positive edge of sw_out)
    output reg          sw_negpulse // debounced output (one clock pulse on negative edge of sw_out)
);

reg     [CONSECUTIVE_SAMPLES-1:0]  shift_reg;
reg     [PRESCALER_WIDTH-1:0]      prescaler_cnt;

always @(posedge clk) begin
    if (!rst_n) begin
        shift_reg <= 16'b0;
        sw_out <= 1'b0;
    end
    else begin
        if (prescaler_cnt == PRESCALER_DIV - 1) begin
            prescaler_cnt <= 0;

            shift_reg <= {shift_reg[CONSECUTIVE_SAMPLES-2:0], sw_in};

            if (shift_reg == {CONSECUTIVE_SAMPLES{1'b1}}) begin
                sw_out <= 1'b1;
                sw_pulse <= ~sw_out;    // only high on rising edge of sw_out
            end
            else if (shift_reg == {CONSECUTIVE_SAMPLES{1'b0}}) begin
                sw_out <= 1'b0;
                sw_negpulse <= ~sw_out;    // only high on falling edge of sw_out
            end
            else begin
                sw_pulse <= 1'b0;
                sw_negpulse <= 1'b0;
            end
        end
        else begin
            prescaler_cnt <= prescaler_cnt + 1;
            sw_pulse <= 1'b0;
            sw_negpulse <= 1'b0;
        end;
    end
end

endmodule