// ============================================================================
// relu_approx.sv
// Project : Hardware Accelerator for Transformer Self-Attention Inference
// Author  : Sri Chandana Reddy Vanukuri — ECE 510 Spring 2026
// ----------------------------------------------------------------------------
// Description:
//   ReLU-based softmax approximation unit. Clips negative attention scores
//   to zero, retaining only positive scores for the AV weighted sum.
//   This is a synthesizable approximation of softmax that avoids the need
//   for exp() and division operations in hardware.
//
//   ReLU(x) = max(0, x)
//
// Clock domain : Single clock domain (clk). No clock crossings.
// Reset        : Synchronous, active-high.
//
// Port List:
//   clk          input  1-bit    System clock
//   rst          input  1-bit    Synchronous active-high reset
//   data_in      input  32-bit   Scaled attention score (signed)
//   valid_in     input  1-bit    Input valid
//   data_out     output 32-bit   ReLU output (non-negative)
//   valid_out    output 1-bit    Output valid
// ============================================================================

module relu_approx #(
    parameter int DATA_WIDTH = 32
) (
    input  logic                          clk,
    input  logic                          rst,
    input  logic signed [DATA_WIDTH-1:0]  data_in,
    input  logic                          valid_in,
    output logic signed [DATA_WIDTH-1:0]  data_out,
    output logic                          valid_out
);

    always_ff @(posedge clk) begin
        if (rst) begin
            data_out  <= '0;
            valid_out <= 1'b0;
        end else if (valid_in) begin
            // ReLU: if negative set to 0, else pass through
            data_out  <= data_in[DATA_WIDTH-1] ? {DATA_WIDTH{1'b0}} : data_in;
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

endmodule