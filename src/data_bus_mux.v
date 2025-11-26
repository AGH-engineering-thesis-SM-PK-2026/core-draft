/*****************************************************************************
 *  Author: Piotr Kadziela
 *  Description:
 *
 *  Address input:
 *   v31     v23     v15     v7     v0
 *  |XXXXX---------------------------|
 *   ^^1^^
 *        ^^^^^^^^^^^^^2^^^^^^^^^^^^^
 *
 * 1: slave adress
 * 2: passed to the slave as internal address bits, the rest is zeroed.
 *
 *****************************************************************************/

`include "data_bus_mux.vh"


module data_bus_mux #(
  parameter integer N = 4,                      // How many slave devices will be used
  parameter integer SEL_BITS = $clog2(N),       // Number of bits needed to select N devices
  parameter integer LSB_MUX_BIT = 32 - SEL_BITS // Least significant bit used for selecting the slave device.
) (
  // ------------ Core interface ---------------
  output                  core_r_en,        // read enable
  output      [31:0]      core_r_addr,      // 32-bit address
  input       [31:0]      core_r_data,      // 32-bits of data

  output                  core_w_en,        // write enable
  output      [31:0]      core_w_addr,      // 32-bit address
  output      [31:0]      core_w_data,      // 32-bits of data
  output      [3:0]       core_w_strb,      // strobe - which bytes are to be written

  // ---------------- Devices ------------------
  output      [N-1:0]     bus_data_r_en,    // read enable
  output      [32*N-1:0]  bus_data_r_addr,  // 32-bit address
  input       [32*N-1:0]  bus_data_r_data,  // 32-bits of data

  output      [N-1:0]     bus_data_w_en,    // write enable
  output      [32*N-1:0]  bus_data_w_addr,  // 32-bit address
  output      [32*N-1:0]  bus_data_w_data,  // 32-bits of data
  output      [4*N-1:0]   bus_data_w_strb   // strobe - which bytes are to be written
);

// Determine which slave to select based on the address
wire [SEL_BITS-1:0] read_sel  = core_r_addr[31:LSB_MUX_BIT];
wire [SEL_BITS-1:0] write_sel = core_w_addr[31:LSB_MUX_BIT];

assign bus_data_r_en    = ({ {(N-1){1'b0}}, core_r_en }     << read_sel);
assign bus_data_r_addr  = ({ {(N-1){32'b0}}, core_r_addr }  << `N_th_WORD_BEGIN(read_sel));
assign core_r_data      = bus_data_r_data >> `N_th_WORD_BEGIN(read_sel);

assign bus_data_w_en    = ({ {(N-1){1'b0}}, core_w_en }     << read_sel);
assign bus_data_w_addr  = ({ {(N-1){32'b0}}, core_w_addr }  << `N_th_WORD_BEGIN(write_sel));
assign bus_data_w_data  = ({ {(N-1){32'b0}}, core_w_data }  << `N_th_WORD_BEGIN(write_sel));
assign bus_data_w_strb  = ({ {(N-1){4'b0}}, core_w_strb }   << `N_th_STRB_BEGIN(write_sel));

endmodule