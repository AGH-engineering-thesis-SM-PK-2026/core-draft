/*****************************************************************************
 *  Author: Piotr Kadziela
 *  Description:
 *      Clock Management Unit (CMU) for RIVER core.

 *  There are three allowed modes of operation for this MCU:
 *      - Normal operation mode: The core executes instructions at the given 
 *          clock frequency.
 *      - Single step mode: The core executes one full cycle per external 
 *          trigger signal.
 *      - Single cycle mode: The core executes one step (either FE, DE, EX, 
 *          MEM or WB) per external trigger signal.
 *  Defaut mode is normal operation mode. When clock_supress is high, the core
 *  will stop operation until triggered by either trig_step or trig_cycle.
 *
 *  INPUTS SHOULD BE DEBOUNCED AND NOT LONGER THAN ONE CLOCK CYCLE WIDE!
 *****************************************************************************/

`define CMU_STATE_RUNNING       2'b00   // normal operation mode
`define CMU_STATE_STEP          2'b01   // single step in progress
`define CMU_STATE_CYCLE         2'b10   // single cycle in progress
`define CMU_STATE_AWAIT_TRIG    2'b11   // waiting for trigger

module cmu (
    input               clk_in,
    input               rst_n,

    input               clock_supress,  // when high, the core is stopped
    input               trig_step,     // trigger single step (one clock tick)
    input               trig_cycle,    // trigger single cycle (one full instruction)

    input               cycle_end,      // input signal from the core indicating the end of a full instruction cycle

    output              state_out,      // current CMU state
    output reg          clk_enable      // output clock to the core
);

state reg     [1:0]   state;

assign state_out = state;

always @(posedge clk_in or posedge rst_n) begin
    if (!rst_n) begin
        
    end
    else begin
        if (!clock_supress) begin
            state <= `CMU_STATE_RUNNING;
            clk_enable <= 1'b1;
        end
        else begin
            case (state)
                `CMU_STATE_RUNNING: begin
                    // Finish the current cycle and await trigger
                    state <= `CMU_STATE_CYCLE;
                    clk_enable <= 1'b0;
                end
                `CMU_STATE_STEP: begin
                    // Single step completed
                    state <= `CMU_STATE_AWAIT_TRIG;
                    clk_enable <= 1'b0;
                end
                `CMU_STATE_CYCLE: begin
                    // Keep running until cycle ends
                    if (cycle_end) begin
                        // Full cycle completed
                        state <= `CMU_STATE_AWAIT_TRIG;
                        clk_enable <= 1'b0;
                    end
                end
                `CMU_STATE_AWAIT_TRIG: begin
                    // Do nothing until triggered
                    clk_enable <= 1'b0;
                    if (trig_step) begin
                        state <= `CMU_STATE_STEP;
                        clk_enable <= 1'b1;
                    end
                    else if (trig_cycle) begin
                        state <= `CMU_STATE_CYCLE;
                        clk_enable <= 1'b1;
                    end
                end
            endcase
        end
    end
end




endmodule