`timescale 1ns / 1ps
/*****************************************************************************
 *  Author: Piotr Kadziela
 *  Description:
 *      Simple timer peripheral with memory-mapped interface.
 *      Provides a 32-bit counter register, that is incremented every cycle
 *      and can be read and written. It also provides a control register to
 *      enable/disable the timer.
 *      Reads and writes are assumed to be aligined and of word size.
 *****************************************************************************/

module timer (
    input               clk,
    input               n_rst,
    input               clk_enable,   // clock enable signal

    // Data bus interface
    input               bus_r_en,      // read enable
    input       [31:0]  bus_r_addr,    // 32-bit address
    output      [31:0]  bus_r_data,    // 32-bits of data

    input               bus_w_en,      // write enable
    input       [31:0]  bus_w_addr,    // 32-bit address
    input       [31:0]  bus_w_data     // 32-bits of data
);

// Timer registers
reg [31:0] counter;      // 32-bit counter register
reg        control;      // control register: high = enabled, low = disabled

always @(posedge clk) begin
    if (!n_rst) begin
        counter <= 32'b0;
        control <= 1'b1;    // enabled by default
    end
    else if (clk_enable) begin
        // Increment counter if enabled
        counter <= counter + control;

        // Handle write operations
        if (bus_w_en) begin
            case (bus_w_addr)
                32'h00000000: counter <= bus_w_data; // Write to counter register
                32'h00000004: control <= bus_w_data[0]; // Write to control register (only LSB used)
                default: ; // Ignore writes to other addresses
            endcase
        end
    end
end

assign bus_r_data = (bus_r_addr == 32'h00000000 && bus_r_en) ? counter
                    : (bus_r_addr == 32'h00000004 && bus_r_en) ? {31'b0, control}
                    : 32'b0;

endmodule