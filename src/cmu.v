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
 *  Defaut mode is normal operation mode.
 *  When halt signal is received, the core finishes the current cycle and
 *  enters await trigger mode. Halt signal may be generated internally 
 *  (e.g. by a breakpoint) or externally (e.g. by a debugger).
 *  When in await trigger state, the core will wait until a trigger signal is 
 *  received (either single step, single cycle or unhalt).
 *  Holding the clock_supress high when the core is halted will cause CMU to 
 *  ignore any triggers and keep the core halted.
 *
 *  TRIG INPUTS SHOULD BE DEBOUNCED AND NOT LONGER THAN ONE CLOCK CYCLE WIDE!
 *****************************************************************************/

`define CMU_STATE_RUNNING       0       // normal operation mode
`define CMU_STATE_FINISH_CYCLE  1       // waiting to finish current clock cycle before halting
`define CMU_STATE_HALTED        2       // the core has just been halted. Send debug trigger and wait for one cycle (debug interface may want to supress clock)
`define CMU_STATE_AWAIT_TRIG    3       // halted, waiting for trigger
`define CMU_STATE_STEP          4       // single step in progress

module cmu #(
    parameter INITIAL_STATE = `CMU_STATE_RUNNING
) (
    input               clk_in,
    input               rst_n,

    input               cycle_end,      // input signal from the core indicating the end of a full instruction cycle

    input               trig_halt,      // halt the core (enter await trigger mode on pulse)
    input               clock_supress,  // suppress any triggers

    input               trig_unhalt,    // unhalt the core (enter normal operation mode on pulse)
    input               trig_cycle,     // trigger single cycle (one full instruction)
    input               trig_step,      // trigger single step (one clock tick)

    output              debug_trig,     // output debug trigger on halt to notify debug interface
    output              clk_enable      // output clock to the core
);

reg [2:0]   state;

assign debug_trig = (state == `CMU_STATE_HALTED);
assign clk_enable = (state == `CMU_STATE_RUNNING) || (state == `CMU_STATE_FINISH_CYCLE) || (state == `CMU_STATE_STEP);

always @(posedge clk_in) begin
    if (!rst_n) begin
        state <= INITIAL_STATE;
    end
    else begin
        case (state)
            `CMU_STATE_RUNNING: begin
                if (trig_halt)
                    state <= `CMU_STATE_FINISH_CYCLE;
            end
            `CMU_STATE_FINISH_CYCLE: begin
                // Wait until the current clock cycle is finished
                if (cycle_end) begin
                    state <= `CMU_STATE_HALTED;
                end
            end
            `CMU_STATE_HALTED: begin
                // After halting, wait for one clock cycle to allow debug interface to react
                state <= `CMU_STATE_AWAIT_TRIG;
            end
            `CMU_STATE_AWAIT_TRIG: begin
                if (!clock_supress) begin
                    if (trig_unhalt) begin
                        state <= `CMU_STATE_RUNNING;
                    end
                    else if (trig_cycle) begin
                        state <= `CMU_STATE_FINISH_CYCLE;
                    end
                    else if (trig_step) begin
                        state <= `CMU_STATE_STEP;
                    end
                end
            end
            `CMU_STATE_STEP: begin
                // After one clock cycle, return to await trigger state
                state <= `CMU_STATE_HALTED;
            end
        endcase
    end
end

endmodule