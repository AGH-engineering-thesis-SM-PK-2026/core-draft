`timescale 1ns / 1ps
/*****************************************************************************
 *  Author: Szymon Miekina
 *  Description:
 *      Global data bus for data memory and all user peripherals.
 *      It does not try to modify address and data dataflow and acts
 *      as a switch for all read/write requests:
 *      - All memories/peripherals get current addresses, but only
 *        one of them (or none if invalid address is given) can receive enable
 *        signal, triggering read or write operation;
 *      - The r_data output is demultiplexed (selected) from memories/peripherals
 *        r_datas outputs; This requires the r_addr input to remain stable during
 *        the whole duration of read operation.
 *      
 *      Memory Map:
 *      00000000..000003ff (  1K) -- (unallocated)
 *      00000400..000007ff (  1K) -- GPIO A
 *      00000800..00000fff (  2K) -- (unallocated)
 *      00001000..00001fff (  4K) -- Data Memory
 *      00002000..ffffffff (rest) -- (unallocated)
 *
 *****************************************************************************/

module data_bus (
    input               clk,

    input               r_en,   // read enable
    input       [31:0]  r_addr, // 32-bit address
    output      [31:0]  r_data, // 32-bits of data

    input               w_en,   // write enable
    input       [31:0]  w_addr, // 32-bit address
    input       [31:0]  w_data  // 32-bits of data
);

// mem data - 4K 00001000 - 00001fff
wire sel_mem_data_r = r_addr[15:12] == 4'b0001;
// gpio a - 1K 00000400 - 000007ff
wire sel_gpio_a_r = r_addr[15:10] == 6'b000001;

// only send read enable to selected peripheral/memory
assign mem_data_r_en = sel_mem_data_r ? r_en : 1'b0;
assign gpio_a_r_en = sel_gpio_a_r ? r_en : 1'b0;

// only send write enable to selected peripheral/memory
assign mem_data_w_en = w_addr[15:12] == 4'b0001 ? w_en : 1'b0;
assign gpio_a_w_en = w_addr[15:10] == 6'b000001 ? w_en : 1'b0;

wire [31:0] mem_data_r_data;
wire [31:0] gpio_a_r_data;

// output data from selected peripheral/memory based on read address
assign r_data = 
    sel_mem_data_r ? mem_data_r_data :
    sel_gpio_a_r ? gpio_a_r_data : 1'b0;

// data memory - needs to offset both r_addr & w_addr, so that by accessing
// 00001000 the RAM points to 00000000
memory #(.NAME("DATA"), .INIT_FILE("init_data.mem")) mem_data(
    .clk(clk),
    .r_en(mem_data_r_en),
    .r_addr(r_addr - 32'h1000),
    .r_data(mem_data_r_data),
    .w_en(mem_data_w_en),
    .w_addr(w_addr - 32'h1000),
    .w_data(w_data),
    .state()
);

// gpio a peripheral - also apply offset
gpio gpio_a(
    .clk(clk),
//    .r_en(gpio_a_r_en),
//    .r_addr(r_addr - 32'h400),
//    .r_data(gpio_a_r_data),
    .w_en(gpio_a_w_en),
    .w_addr(w_addr - 32'h400),
    .w_data(w_data)
);

endmodule
