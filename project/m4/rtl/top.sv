// ============================================================================
// top.sv
// Project : Hardware Accelerator for Transformer Self-Attention Inference
// Author  : Sri Chandana Reddy Vanukuri — ECE 510 Spring 2026
// Milestone: M3 — Integration and Synthesis
// ----------------------------------------------------------------------------
// Description:
//   Top-level integration module connecting the AXI4-Stream interface
//   (interface_axi4s) to the full attention pipeline compute core
//   (compute_core). Data flows from the host through the AXI4-Stream
//   slave port, into the compute core, and results return to the host
//   through the AXI4-Stream master port.
//
//   No glue logic is required between the interface and compute core.
//   The interface_axi4s module directly instantiates compute_core
//   internally, so top.sv instantiates interface_axi4s as the single
//   top-level component and exposes only the AXI4-Stream ports to
//   the external host.
//
// Clock domain : Single clock domain (clk). No clock crossings.
// Reset        : Synchronous, active-high (rst = 1 clears all registers)
//
// Port List:
//   clk        input  1-bit    System clock (rising-edge triggered)
//   rst        input  1-bit    Synchronous active-high reset
//   s_tvalid   input  1-bit    Slave TVALID — host sending Q,K,V data
//   s_tready   output 1-bit    Slave TREADY — accelerator ready to accept
//   s_tdata    input  24-bit   Slave TDATA {q_in[7:0], k_in[7:0], v_in[7:0]}
//   s_tlast    input  1-bit    Slave TLAST — last element of sequence
//   m_tvalid   output 1-bit    Master TVALID — result valid
//   m_tready   input  1-bit    Master TREADY — host ready to accept
//   m_tdata    output 32-bit   Master TDATA — attention output (signed)
// ============================================================================

module top #(
    parameter int DATA_WIDTH  = 8,
    parameter int ACCUM_WIDTH = 32,
    parameter int HEAD_DIM    = 64,
    parameter int SCALE_SHIFT = 3
) (
    input  logic                          clk,
    input  logic                          rst,

    // Slave AXI4-Stream — host to accelerator
    input  logic                          s_tvalid,
    output logic                          s_tready,
    input  logic [3*DATA_WIDTH-1:0]       s_tdata,   // {q_in, k_in, v_in}
    input  logic                          s_tlast,

    // Master AXI4-Stream — accelerator to host
    output logic                          m_tvalid,
    input  logic                          m_tready,
    output logic signed [ACCUM_WIDTH-1:0] m_tdata
);

    // ── Instantiate interface_axi4s ───────────────────────────────────────────
    // interface_axi4s internally instantiates compute_core which instantiates
    // all four pipeline submodules (mac_unit, scale_unit, relu_approx, av_unit)
    // No glue logic needed — ports connect directly
    interface_axi4s #(
        .DATA_WIDTH  (DATA_WIDTH),
        .ACCUM_WIDTH (ACCUM_WIDTH)
    ) u_interface (
        .clk      (clk),
        .rst      (rst),
        .s_tvalid (s_tvalid),
        .s_tready (s_tready),
        .s_tdata  (s_tdata),
        .s_tlast  (s_tlast),
        .m_tvalid (m_tvalid),
        .m_tready (m_tready),
        .m_tdata  (m_tdata)
    );

endmodule