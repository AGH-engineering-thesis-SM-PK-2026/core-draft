`timescale 1ns / 1ps

// Bus device endpoint
// The module acts as a pass-through between the device/memory and the CPU
// The device enable will only be passed through when the CPU address is
// within the range. The range is defined by the BASE and MASK values: in fact
// this arrangement is closely related to IPv4 addressing - the MASK specifies
// how many bits at the end of address are device-specific register address.
// With a BASE of 0x12345678 and MASK of 12 the address is split as follows:
// 0001 0010 0011 0100 0101 0110 0111 1000
// | device address       | | register i |
//
// Each device is modelled as a collection of registers - the 'register i'
// selects the register 0x678 of the device at address 0x12345000. The OFFS
// controlls the offset applied to the global address to obtain the reg. addr.
// and should be the same as BASE in 99% of cases.
// Szymon Miękina - 23.11.2025

module busdev #(
    BASE = 32'h00000000,
    OFFS = 32'h00000000,
    MASK = 4
) (
    input               en,         // enable signal from bus
    input       [31:0]  addr,       // address from bus
    output              deven,      // device enable signal
    output  [MASK-1:0]  devaddr,    // address within device
    output              sel         // high when device is selected
);

wire [31-MASK:0] base = addr[31:MASK];

assign deven    = base == BASE ? en : 1'b0;
assign devaddr  = addr[MASK-1:0];
assign sel      = base == BASE;

endmodule
