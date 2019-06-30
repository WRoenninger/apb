// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// APB Read-Only Registers
// This module exposes a number of 32-bit registers (provided on the `reg_i` input) read-only on an
// APB interface.  It responds to reads that are out of range and writes with a slave error.
module apb_ro_regs #(
  parameter int unsigned N_REGS = 0,
  parameter int unsigned ADDR_WIDTH = 0,
  parameter int unsigned DATA_WIDTH = 0,
  localparam type addr_t = logic[ADDR_WIDTH-1:0],
  localparam type data_t = logic[DATA_WIDTH-1:0],
  localparam type strb_t = logic[DATA_WIDTH/8-1:0]
) (
  // APB Interface
  input  logic        pclk_i,
  input  logic        preset_ni,
  input  addr_t       paddr_i,
  input  logic [2:0]  pprot_i,
  input  logic        psel_i,
  input  logic        penable_i,
  input  logic        pwrite_i,
  input  data_t       pwdata_i,
  input  strb_t       pstrb_i,
  output logic        pready_o,
  output data_t       prdata_o,
  output logic        pslverr_o,

  // Register Interface
  input  data_t [N_REGS-1:0] reg_i
);

  localparam int unsigned WORD_OFFSET = $clog2(DATA_WIDTH/8);
  always_comb begin
    prdata_o  = 'x;
    pslverr_o = 1'b0;
    if (psel_i) begin
      if (pwrite_i) begin
        // Error response to writes
        pslverr_o = 1'b1;
      end else begin
        automatic logic [ADDR_WIDTH-WORD_OFFSET-1:0] word_addr = paddr_i >> WORD_OFFSET;
        if (word_addr >= N_REGS) begin
          // Error response to reads out of range
          pslverr_o = 1'b1;
        end else begin
          prdata_o = reg_i[word_addr];
        end
      end
    end
  end
  assign pready_o = psel_i & penable_i;

// Validate parameters.
// pragma translate_off
`ifndef VERILATOR
  initial begin: p_assertions
    assert (N_REGS >= 1) else $fatal(1, "The number of registers must be at least 1!");
  end
`endif
// pragma translate_on

endmodule
