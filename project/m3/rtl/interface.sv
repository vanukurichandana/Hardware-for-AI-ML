// ============================================================================
// interface.sv
// Project : Hardware Accelerator for Transformer Self-Attention Inference
// Author  : Sri Chandana Reddy Vanukuri — ECE 510 Spring 2026
// ----------------------------------------------------------------------------
// Description:
//   AXI4-Stream interface module connecting the host processor to the
//   compute_core. Receives Q, K, V matrix elements from the host via
//   AXI4-Stream slave port, forwards them to the compute core, and
//   streams the attention output back to the host via master port.
//
//   Protocol  : AXI4-Stream (ARM IHI0051B)
//   Data width: 24-bit TDATA = {q_in[7:0], k_in[7:0], v_in[7:0]}
//   Output    : 32-bit attention result streamed back to host
//
//   Transaction format:
//     Write (host -> accelerator):
//       TDATA[23:16] = q_in  (INT8 signed Q element)
//       TDATA[15:8]  = k_in  (INT8 signed K element)
//       TDATA[7:0]   = v_in  (INT8 signed V element)
//       TVALID = 1 when data valid
//       TLAST  = 1 on last element of sequence
//     Read (accelerator -> host):
//       M_TDATA[31:0] = attn_out (32-bit signed result)
//       M_TVALID = 1 when result valid
//       M_TREADY = 1 when host ready to accept
//
// Clock domain : Single clock domain (clk). No clock crossings.
// Reset        : Synchronous, active-high (rst = 1 clears all registers)
//
// Port List:
//   clk        input  1-bit    System clock
//   rst        input  1-bit    Synchronous active-high reset
//   s_tvalid   input  1-bit    Slave TVALID (host sending data)
//   s_tready   output 1-bit    Slave TREADY (accelerator ready)
//   s_tdata    input  24-bit   Slave TDATA {q_in, k_in, v_in}
//   s_tlast    input  1-bit    Slave TLAST (last element of sequence)
//   m_tvalid   output 1-bit    Master TVALID (result valid)
//   m_tready   input  1-bit    Master TREADY (host ready)
//   m_tdata    output 32-bit   Master TDATA (attention result)
// ============================================================================

module interface_axi4s #(
    parameter int DATA_WIDTH  = 8,
    parameter int ACCUM_WIDTH = 32
) (
    input  logic                          clk,
    input  logic                          rst,

    // Slave AXI4-Stream (host -> accelerator)
    input  logic                          s_tvalid,
    output logic                          s_tready,
    input  logic [3*DATA_WIDTH-1:0]       s_tdata,   // {q_in, k_in, v_in}
    input  logic                          s_tlast,

    // Master AXI4-Stream (accelerator -> host)
    output logic                          m_tvalid,
    input  logic                          m_tready,
    output logic signed [ACCUM_WIDTH-1:0] m_tdata
);

    // ── Unpack TDATA ──────────────────────────────────────────────────────────
    logic signed [DATA_WIDTH-1:0] q_in;
    logic signed [DATA_WIDTH-1:0] k_in;
    logic signed [DATA_WIDTH-1:0] v_in;

    assign q_in = signed'(s_tdata[3*DATA_WIDTH-1 : 2*DATA_WIDTH]);
    assign k_in = signed'(s_tdata[2*DATA_WIDTH-1 :   DATA_WIDTH]);
    assign v_in = signed'(s_tdata[  DATA_WIDTH-1 :           0]);

    // ── Handshake signals ─────────────────────────────────────────────────────
    assign s_tready = ~rst;

    logic valid_in;
    logic seq_last;
    assign valid_in = s_tvalid & s_tready;
    assign seq_last = s_tlast  & s_tready;

    // ── Instantiate compute core ──────────────────────────────────────────────
    logic signed [ACCUM_WIDTH-1:0] core_attn_out;
    logic                          core_valid_out;

    compute_core #(
        .DATA_WIDTH  (DATA_WIDTH),
        .ACCUM_WIDTH (ACCUM_WIDTH)
    ) u_compute_core (
        .clk       (clk),
        .rst       (rst),
        .q_in      (q_in),
        .k_in      (k_in),
        .v_in      (v_in),
        .valid_in  (valid_in),
        .seq_last  (seq_last),
        .attn_out  (core_attn_out),
        .valid_out (core_valid_out)
    );

    // ── Output register ───────────────────────────────────────────────────────
    logic signed [ACCUM_WIDTH-1:0] result_reg;
    logic                          result_valid;

    always_ff @(posedge clk) begin
        if (rst) begin
            result_reg   <= '0;
            result_valid <= 1'b0;
        end else if (core_valid_out) begin
            result_reg   <= core_attn_out;
            result_valid <= 1'b1;
        end else if (m_tready & result_valid) begin
            result_valid <= 1'b0;
        end
    end

    assign m_tvalid = result_valid;
    assign m_tdata  = result_reg;

endmodule