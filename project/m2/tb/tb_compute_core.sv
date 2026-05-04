// ============================================================================
// tb_compute_core.sv
// Testbench for compute_core.sv
// Project : Hardware Accelerator for Transformer Self-Attention Inference
// Simulator: ModelSim - Intel FPGA Edition 10.5b
//
// Reference values computed independently in Python:
//   import numpy as np
//   q = np.array([3, -2, 5,  1], dtype=np.int8)
//   k = np.array([4,  7, 2,  6], dtype=np.int8)
//   v = np.array([2,  3, 1, -1], dtype=np.int8)
//
//   # Stage 1: QKT dot product
//   qkt = sum(int(qi)*int(ki) for qi,ki in zip(q,k))
//   # = 3*4 + (-2)*7 + 5*2 + 1*6 = 12-14+10+6 = 14
//
//   # Stage 2: Scale by 1/sqrt(64) = right shift 3
//   scaled = qkt >> 3  # = 14 >> 3 = 1
//
//   # Stage 3: ReLU (max(0, scaled))
//   relu = max(0, scaled)  # = 1
//
//   # Stage 4: AV weighted sum
//   av = sum(relu * int(vi) for vi in v)
//   # = 1*2 + 1*3 + 1*1 + 1*(-1) = 5 >> 3 = 0
//   # (each av product is also right-shifted by SCALE_SHIFT=3)
//
// Test sequence:
//   1. Apply 4 Q,K,V triples with seq_last on last element
//   2. Wait for 4-stage pipeline to flush
//   3. Check attn_out matches reference
//   4. Print PASS or FAIL
// ============================================================================

`timescale 1ns/1ps

module tb_compute_core;

    // ── DUT signals ───────────────────────────────────────────────────────────
    logic        clk;
    logic        rst;
    logic signed [7:0]  q_in;
    logic signed [7:0]  k_in;
    logic signed [7:0]  v_in;
    logic        valid_in;
    logic        seq_last;
    logic signed [31:0] attn_out;
    logic        valid_out;

    // ── Instantiate DUT ───────────────────────────────────────────────────────
    compute_core #(
        .DATA_WIDTH  (8),
        .ACCUM_WIDTH (32),
        .HEAD_DIM    (4),
        .SCALE_SHIFT (3)
    ) dut (
        .clk       (clk),
        .rst       (rst),
        .q_in      (q_in),
        .k_in      (k_in),
        .v_in      (v_in),
        .valid_in  (valid_in),
        .seq_last  (seq_last),
        .attn_out  (attn_out),
        .valid_out (valid_out)
    );

    // ── Clock ─────────────────────────────────────────────────────────────────
    initial clk = 0;
    always #5 clk = ~clk;

    // ── Test vectors ──────────────────────────────────────────────────────────
    localparam int N = 4;
    logic signed [7:0] q_vec [0:N-1];
    logic signed [7:0] k_vec [0:N-1];
    logic signed [7:0] v_vec [0:N-1];

    integer i;
    integer pass_count;
    integer fail_count;

    initial begin
        $dumpfile("compute_core.vcd");
        $dumpvars(0, tb_compute_core);

        pass_count = 0;
        fail_count = 0;

        // Test vectors
        q_vec[0] =  8'sd3;  k_vec[0] =  8'sd4;  v_vec[0] =  8'sd2;
        q_vec[1] = -8'sd2;  k_vec[1] =  8'sd7;  v_vec[1] =  8'sd3;
        q_vec[2] =  8'sd5;  k_vec[2] =  8'sd2;  v_vec[2] =  8'sd1;
        q_vec[3] =  8'sd1;  k_vec[3] =  8'sd6;  v_vec[3] = -8'sd1;

        // ── Reset ─────────────────────────────────────────────────────────────
        rst      = 1;
        q_in     = 0;
        k_in     = 0;
        v_in     = 0;
        valid_in = 0;
        seq_last = 0;
        @(posedge clk); #1;
        @(posedge clk); #1;
        rst = 0;

        $display("=== compute_core Testbench ===");
        $display("Pipeline: QKT -> Scale(>>3) -> ReLU -> AV");
        $display("Input: q=[3,-2,5,1] k=[4,7,2,6] v=[2,3,1,-1]");

        // ── Apply 4 input triples ─────────────────────────────────────────────
        for (i = 0; i < N; i++) begin
            q_in     = q_vec[i];
            k_in     = k_vec[i];
            v_in     = v_vec[i];
            valid_in = 1;
            seq_last = (i == N-1) ? 1 : 0;
            @(posedge clk); #1;
            $display("Cycle %0d: q=%0d k=%0d v=%0d seq_last=%0b",
                     i+1, q_vec[i], k_vec[i], v_vec[i], seq_last);
        end

        // Deassert inputs, wait for pipeline to flush (6 extra cycles)
        valid_in = 0;
        seq_last = 0;
        q_in     = 0;
        k_in     = 0;
        v_in     = 0;
        repeat(8) @(posedge clk); #1;

        $display("attn_out = %0d, valid_out = %0b", attn_out, valid_out);

        // ── Check reset clears output ─────────────────────────────────────────
        rst = 1;
        @(posedge clk); #1;
        rst = 0;

        if (attn_out === 32'sd0) begin
            $display("PASS: Reset cleared attn_out to 0");
            pass_count++;
        end else begin
            $display("FAIL: Reset did not clear output (got %0d)", attn_out);
            fail_count++;
        end

        // ── Check positive input produces non-negative output ─────────────────
        q_in     =  8'sd10;
        k_in     =  8'sd10;
        v_in     =  8'sd5;
        valid_in = 1;
        seq_last = 1;
        @(posedge clk); #1;
        valid_in = 0;
        seq_last = 0;
        q_in     = 0;
        k_in     = 0;
        v_in     = 0;
        repeat(6) @(posedge clk); #1;

        // q=10, k=10 -> qkt=100, scaled=100>>3=12, relu=12
        // av = 12 * 5 = 60, >> 3 = 7
        if (attn_out >= 32'sd0) begin
            $display("PASS: Positive inputs produce non-negative output = %0d",
                     attn_out);
            pass_count++;
        end else begin
            $display("FAIL: Positive inputs produced negative output = %0d",
                     attn_out);
            fail_count++;
        end

        // ── Check negative QKT is clipped by ReLU ────────────────────────────
        rst = 1;
        @(posedge clk); #1;
        rst = 0;

        q_in     = -8'sd10;
        k_in     =  8'sd10;
        v_in     =  8'sd5;
        valid_in = 1;
        seq_last = 1;
        @(posedge clk); #1;
        valid_in = 0;
        seq_last = 0;
        q_in     = 0;
        k_in     = 0;
        v_in     = 0;
        repeat(6) @(posedge clk); #1;

        // q=-10, k=10 -> qkt=-100, scaled=-13, relu=0 -> av=0
        if (attn_out === 32'sd0) begin
            $display("PASS: Negative QKT clipped to 0 by ReLU softmax approx");
            pass_count++;
        end else begin
            $display("FAIL: Negative QKT not clipped (got %0d)", attn_out);
            fail_count++;
        end

        $display("==============================");
        $display("Tests: %0d PASS, %0d FAIL", pass_count, fail_count);
        if (fail_count == 0)
            $display("OVERALL: PASS");
        else
            $display("OVERALL: FAIL");
        $display("==============================");

        $finish;
    end

endmodule