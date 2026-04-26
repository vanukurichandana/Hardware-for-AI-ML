// attention_mac_core.sv
// Project: Hardware Accelerator for Transformer Self-Attention Inference
// Author:  Sri Chandana Reddy Vanukuri — ECE 510 Spring 2026
//
// Description:
//   Top-level compute core for the QxK^T dot product engine.
//   Implements a 2-stage pipelined MAC unit:
//     Stage 1: Multiply Q and K elements (INT8 x INT8 = INT16)
//     Stage 2: Sign-extend and accumulate into 32-bit register
//
// Precision: INT8 inputs, FP32-equivalent 32-bit accumulator
// Interface: AXI4-Stream (planned for M2)
//
// Compile check:
//   vlog -sv attention_mac_core.sv (ModelSim)
// Note: Simulation testbench in attention_mac_core_tb.py (cocotb — planned for M2)

module attention_mac_core #(
    parameter int DATA_WIDTH  = 8,    // INT8 input precision
    parameter int ACCUM_WIDTH = 32,   // 32-bit accumulator (FP32-equivalent)
    parameter int SEQ_LEN     = 64,   // Sequence length T (from sw_baseline)
    parameter int HEAD_DIM    = 64    // d_k = model_dim / num_heads
) (
    input  logic                          clk,
    input  logic                          rst,        // active-high synchronous reset

    // Q and K input elements (one pair per cycle)
    input  logic signed [DATA_WIDTH-1:0]  q_in,      // Q matrix element (INT8)
    input  logic signed [DATA_WIDTH-1:0]  k_in,      // K matrix element (INT8)
    input  logic                          valid_in,   // asserted when q_in/k_in are valid

    // Accumulated dot product output
    output logic signed [ACCUM_WIDTH-1:0] accum_out,  // running dot product
    output logic                          valid_out    // asserted when accum_out is valid
);

    // ── Stage 1: Multiply ───────────────────────────────────────────────────
    // INT8 x INT8 → INT16 signed product, registered
    logic signed [2*DATA_WIDTH-1:0] product_reg;
    logic                           valid_stage1;

    always_ff @(posedge clk) begin
        if (rst) begin
            product_reg  <= '0;
            valid_stage1 <= 1'b0;
        end else begin
            product_reg  <= q_in * k_in;   // signed 8x8 → 16-bit result
            valid_stage1 <= valid_in;
        end
    end

    // ── Stage 2: Sign-extend and accumulate ────────────────────────────────
    // Explicit sign extension: replicate MSB of 16-bit product to fill 32 bits
    // This avoids implicit/tool-dependent zero-extension of negative products
    always_ff @(posedge clk) begin
        if (rst) begin
            accum_out <= '0;
            valid_out <= 1'b0;
        end else if (valid_stage1) begin
            accum_out <= accum_out +
                         {{(ACCUM_WIDTH - 2*DATA_WIDTH){product_reg[2*DATA_WIDTH-1]}},
                          product_reg};
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

endmodule