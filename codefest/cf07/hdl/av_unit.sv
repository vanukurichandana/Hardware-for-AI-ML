// ============================================================================
// av_unit.sv
// Project : Hardware Accelerator for Transformer Self-Attention Inference
// Author  : Sri Chandana Reddy Vanukuri — ECE 510 Spring 2026
// ----------------------------------------------------------------------------
// Description:
//   Attention-weighted Value (AV) accumulation unit. Multiplies the
//   attention weight (from relu_approx) with the V matrix element and
//   accumulates the result into a 32-bit signed register.
//   Result is right-shifted by SCALE_SHIFT to prevent overflow.
//
// Clock domain : Single clock domain (clk). No clock crossings.
// Reset        : Synchronous, active-high.
//
// Port List:
//   clk          input  1-bit    System clock
//   rst          input  1-bit    Synchronous active-high reset
//   weight_in    input  32-bit   Attention weight from ReLU stage
//   v_in         input  8-bit    V matrix element (INT8 signed)
//   valid_in     input  1-bit    Input valid
//   result_out   output 32-bit   Accumulated AV output (signed)
//   valid_out    output 1-bit    Output valid
// ============================================================================

module av_unit #(
    parameter int DATA_WIDTH  = 8,
    parameter int ACCUM_WIDTH = 32,
    parameter int SCALE_SHIFT = 3
) (
    input  logic                           clk,
    input  logic                           rst,
    input  logic signed [ACCUM_WIDTH-1:0]  weight_in,
    input  logic signed [DATA_WIDTH-1:0]   v_in,
    input  logic                           valid_in,
    output logic signed [ACCUM_WIDTH-1:0]  result_out,
    output logic                           valid_out
);

    logic signed [ACCUM_WIDTH-1:0] v_extended;
    logic signed [ACCUM_WIDTH-1:0] av_accum;

    always_ff @(posedge clk) begin
        if (rst) begin
            v_extended <= '0;
            av_accum   <= '0;
            valid_out  <= 1'b0;
        end else if (valid_in) begin
            v_extended <= {{(ACCUM_WIDTH-DATA_WIDTH){v_in[DATA_WIDTH-1]}}, v_in};
            av_accum   <= av_accum +
                          ((weight_in * v_extended) >>> SCALE_SHIFT);
            valid_out  <= 1'b1;
        end else begin
            valid_out  <= 1'b0;
        end
    end

    assign result_out = av_accum;

endmodule