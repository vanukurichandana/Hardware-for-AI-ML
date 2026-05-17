// ============================================================================
// compute_core.sv  (top-level)
// Project : Hardware Accelerator for Transformer Self-Attention Inference
// Author  : Sri Chandana Reddy Vanukuri — ECE 510 Spring 2026
// ----------------------------------------------------------------------------
// Description:
//   Top-level compute core for the full scaled dot-product attention pipeline.
//   Instantiates four submodules in sequence:
//
//     mac_unit    -> Stage 1: QKᵀ dot product (INT8 x INT8 -> 32-bit accum)
//     scale_unit  -> Stage 2: Scale by 1/sqrt(d_k) via arithmetic right shift
//     relu_approx -> Stage 3: Softmax approximation (ReLU clips negatives)
//     av_unit     -> Stage 4: AV weighted sum (attention weight x V element)
//
// Clock domain : Single clock domain (clk). No clock crossings.
// Reset        : Synchronous, active-high (rst = 1 clears all registers)
//
// Port List:
//   clk        input  1-bit    System clock (rising-edge triggered)
//   rst        input  1-bit    Synchronous active-high reset
//   q_in       input  8-bit    Q matrix element (INT8 signed)
//   k_in       input  8-bit    K matrix element (INT8 signed)
//   v_in       input  8-bit    V matrix element (INT8 signed)
//   valid_in   input  1-bit    Asserted when inputs are valid
//   seq_last   input  1-bit    Asserted on last element of dot product
//   attn_out   output 32-bit   Final attention output (signed)
//   valid_out  output 1-bit    Asserted when attn_out is valid
// ============================================================================

module synth_top #(
    parameter int DATA_WIDTH  = 8,
    parameter int ACCUM_WIDTH = 32,
    parameter int HEAD_DIM    = 64,
    parameter int SCALE_SHIFT = 3
) (
    input  logic                           clk,
    input  logic                           rst,
    input  logic signed [DATA_WIDTH-1:0]   q_in,
    input  logic signed [DATA_WIDTH-1:0]   k_in,
    input  logic signed [DATA_WIDTH-1:0]   v_in,
    input  logic                           valid_in,
    input  logic                           seq_last,
    output logic signed [ACCUM_WIDTH-1:0]  attn_out,
    output logic                           valid_out
);

    // ── Stage 1 → Stage 2 signals ─────────────────────────────────────────────
    logic signed [ACCUM_WIDTH-1:0] mac_accum;
    logic                          mac_last;

    // ── Stage 2 → Stage 3 signals ─────────────────────────────────────────────
    logic signed [ACCUM_WIDTH-1:0] scaled_data;
    logic                          scaled_valid;

    // ── Stage 3 → Stage 4 signals ─────────────────────────────────────────────
    logic signed [ACCUM_WIDTH-1:0] relu_data;
    logic                          relu_valid;

    // ── Stage 1: QKᵀ MAC unit ────────────────────────────────────────────────
    mac_unit #(
        .DATA_WIDTH  (DATA_WIDTH),
        .ACCUM_WIDTH (ACCUM_WIDTH)
    ) u_mac (
        .clk       (clk),
        .rst       (rst),
        .a_in      (q_in),
        .b_in      (k_in),
        .valid_in  (valid_in),
        .seq_last  (seq_last),
        .accum_out (mac_accum),
        .last_out  (mac_last)
    );

    // ── Stage 2: Scale by 1/sqrt(d_k) ────────────────────────────────────────
    scale_unit #(
        .DATA_WIDTH  (ACCUM_WIDTH),
        .SCALE_SHIFT (SCALE_SHIFT)
    ) u_scale (
        .clk       (clk),
        .rst       (rst),
        .data_in   (mac_accum),
        .valid_in  (mac_last),
        .data_out  (scaled_data),
        .valid_out (scaled_valid)
    );

    // ── Stage 3: ReLU softmax approximation ──────────────────────────────────
    relu_approx #(
        .DATA_WIDTH (ACCUM_WIDTH)
    ) u_relu (
        .clk       (clk),
        .rst       (rst),
        .data_in   (scaled_data),
        .valid_in  (scaled_valid),
        .data_out  (relu_data),
        .valid_out (relu_valid)
    );

    // ── Stage 4: AV weighted sum ─────────────────────────────────────────────
    av_unit #(
        .DATA_WIDTH  (DATA_WIDTH),
        .ACCUM_WIDTH (ACCUM_WIDTH),
        .SCALE_SHIFT (SCALE_SHIFT)
    ) u_av (
        .clk        (clk),
        .rst        (rst),
        .weight_in  (relu_data),
        .v_in       (v_in),
        .valid_in   (relu_valid),
        .result_out (attn_out),
        .valid_out  (valid_out)
    );

endmodule
