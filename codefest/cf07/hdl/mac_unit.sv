// ============================================================================
// mac_unit.sv
// Project : Hardware Accelerator for Transformer Self-Attention Inference
// Author  : Sri Chandana Reddy Vanukuri — ECE 510 Spring 2026
// ----------------------------------------------------------------------------
// Description:
//   Pipelined INT8 Multiply-Accumulate unit.
//   Multiplies two INT8 signed inputs and accumulates the sign-extended
//   16-bit product into a 32-bit signed accumulator over HEAD_DIM cycles.
//
// Clock domain : Single clock domain (clk). No clock crossings.
// Reset        : Synchronous, active-high.
//
// Port List:
//   clk        input  1-bit    System clock
//   rst        input  1-bit    Synchronous active-high reset
//   a_in       input  8-bit    First operand (INT8 signed)
//   b_in       input  8-bit    Second operand (INT8 signed)
//   valid_in   input  1-bit    Input valid
//   seq_last   input  1-bit    Last element of dot product sequence
//   accum_out  output 32-bit   Accumulated dot product (signed)
//   last_out   output 1-bit    Pulses high when accumulation complete
// ============================================================================

module mac_unit #(
    parameter int DATA_WIDTH  = 8,
    parameter int ACCUM_WIDTH = 32
) (
    input  logic                           clk,
    input  logic                           rst,
    input  logic signed [DATA_WIDTH-1:0]   a_in,
    input  logic signed [DATA_WIDTH-1:0]   b_in,
    input  logic                           valid_in,
    input  logic                           seq_last,
    output logic signed [ACCUM_WIDTH-1:0]  accum_out,
    output logic                           last_out
);

    logic signed [2*DATA_WIDTH-1:0] product_reg;
    logic signed [ACCUM_WIDTH-1:0]  accum_reg;
    logic                           last_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            product_reg <= '0;
            accum_reg   <= '0;
            last_reg    <= 1'b0;
        end else if (valid_in) begin
            product_reg <= a_in * b_in;
            accum_reg   <= accum_reg +
                           {{(ACCUM_WIDTH-2*DATA_WIDTH){product_reg[2*DATA_WIDTH-1]}},
                            product_reg};
            last_reg    <= seq_last;
        end else begin
            last_reg    <= 1'b0;
        end
    end

    assign accum_out = accum_reg;
    assign last_out  = last_reg;

endmodule