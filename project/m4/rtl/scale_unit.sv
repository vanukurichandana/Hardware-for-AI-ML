// ============================================================================
// scale_unit.sv
// Project : Hardware Accelerator for Transformer Self-Attention Inference
// Author  : Sri Chandana Reddy Vanukuri — ECE 510 Spring 2026
// ----------------------------------------------------------------------------
// Description:
//   Fixed-point scaling unit. Approximates division by sqrt(d_k) using
//   arithmetic right shift. For d_k=64, sqrt(64)=8, so shift right by 3.
//
// Clock domain : Single clock domain (clk). No clock crossings.
// Reset        : Synchronous, active-high.
//
// Port List:
//   clk          input  1-bit    System clock
//   rst          input  1-bit    Synchronous active-high reset
//   data_in      input  32-bit   Input value to scale (signed)
//   valid_in     input  1-bit    Input valid
//   data_out     output 32-bit   Scaled output (signed)
//   valid_out    output 1-bit    Output valid
// ============================================================================

module scale_unit #(
    parameter int DATA_WIDTH  = 32,
    parameter int SCALE_SHIFT = 3     // divide by 2^3 = 8 = sqrt(64)
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
            data_out  <= data_in >>> SCALE_SHIFT;
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

endmodule