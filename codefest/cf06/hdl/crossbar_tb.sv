// ============================================================================
// crossbar_tb.sv
// Testbench for crossbar_mac.sv
// Codefest 6 — ECE 410/510 Spring 2026
// Simulator: ModelSim - Intel FPGA Edition 10.5b
//
// Weight matrix W (row i, col j):
//   W = [[ 1, -1,  1, -1],
//        [ 1,  1, -1, -1],
//        [-1,  1,  1, -1],
//        [-1, -1, -1,  1]]
//
// Input vector: in = [10, 20, 30, 40]
//
// Hand-calculated expected outputs:
//   out[0] = W[0][0]*10 + W[1][0]*20 + W[2][0]*30 + W[3][0]*40
//          =  1*10 +  1*20 + (-1)*30 + (-1)*40 = 10+20-30-40 = -40
//   out[1] = W[0][1]*10 + W[1][1]*20 + W[2][1]*30 + W[3][1]*40
//          = -1*10 +  1*20 +  1*30 + (-1)*40 = -10+20+30-40 =   0
//   out[2] = W[0][2]*10 + W[1][2]*20 + W[2][2]*30 + W[3][2]*40
//          =  1*10 + (-1)*20 + 1*30 + (-1)*40 = 10-20+30-40 = -20
//   out[3] = W[0][3]*10 + W[1][3]*20 + W[2][3]*30 + W[3][3]*40
//          = -1*10 + (-1)*20 + (-1)*30 +  1*40 = -10-20-30+40 = -20
// ============================================================================

`timescale 1ns/1ps

module crossbar_tb;

    // ── DUT signals ───────────────────────────────────────────────────────────
    logic        clk;
    logic        rst;
    logic        load_w;
    logic signed [1:0]  weight_in [0:3][0:3];
    logic signed [7:0]  in_vec    [0:3];
    logic        valid_in;
    logic signed [31:0] out_vec   [0:3];
    logic        valid_out;

    // ── Instantiate DUT ───────────────────────────────────────────────────────
    crossbar_mac #(
        .N        (4),
        .IN_WIDTH (8),
        .OUT_WIDTH(32)
    ) dut (
        .clk        (clk),
        .rst        (rst),
        .load_w     (load_w),
        .weight_in  (weight_in),
        .in_vec     (in_vec),
        .valid_in   (valid_in),
        .out_vec    (out_vec),
        .valid_out  (valid_out)
    );

    // ── Clock ─────────────────────────────────────────────────────────────────
    initial clk = 0;
    always #5 clk = ~clk;

    // ── Expected values (hand-calculated) ────────────────────────────────────
    localparam signed [31:0] EXP0 = -32'sd40;
    localparam signed [31:0] EXP1 =  32'sd0;
    localparam signed [31:0] EXP2 = -32'sd20;
    localparam signed [31:0] EXP3 = -32'sd20;

    integer pass_count;
    integer fail_count;

    initial begin
        $dumpfile("crossbar.vcd");
        $dumpvars(0, crossbar_tb);

        pass_count = 0;
        fail_count = 0;

        // ── Reset ─────────────────────────────────────────────────────────────
        rst      = 1;
        load_w   = 0;
        valid_in = 0;
        for (int i = 0; i < 4; i++) in_vec[i] = 0;
        for (int i = 0; i < 4; i++)
            for (int j = 0; j < 4; j++)
                weight_in[i][j] = 2'sb01;
        @(posedge clk); #1;
        @(posedge clk); #1;
        rst = 0;

        $display("=== crossbar_mac Testbench ===");
        $display("Weight matrix:");
        $display("  W = [[ 1,-1, 1,-1],");
        $display("       [ 1, 1,-1,-1],");
        $display("       [-1, 1, 1,-1],");
        $display("       [-1,-1,-1, 1]]");
        $display("Input: in = [10, 20, 30, 40]");

        // ── Load weight matrix ────────────────────────────────────────────────
        // Row 0: [ 1, -1,  1, -1]
        weight_in[0][0] = 2'sb01;  weight_in[0][1] = 2'sb11;
        weight_in[0][2] = 2'sb01;  weight_in[0][3] = 2'sb11;
        // Row 1: [ 1,  1, -1, -1]
        weight_in[1][0] = 2'sb01;  weight_in[1][1] = 2'sb01;
        weight_in[1][2] = 2'sb11;  weight_in[1][3] = 2'sb11;
        // Row 2: [-1,  1,  1, -1]
        weight_in[2][0] = 2'sb11;  weight_in[2][1] = 2'sb01;
        weight_in[2][2] = 2'sb01;  weight_in[2][3] = 2'sb11;
        // Row 3: [-1, -1, -1,  1]
        weight_in[3][0] = 2'sb11;  weight_in[3][1] = 2'sb11;
        weight_in[3][2] = 2'sb11;  weight_in[3][3] = 2'sb01;

        load_w = 1;
        @(posedge clk); #1;
        load_w = 0;
        $display("Weights loaded.");

        // ── Apply input vector [10, 20, 30, 40] ───────────────────────────────
        in_vec[0] = 8'sd10;
        in_vec[1] = 8'sd20;
        in_vec[2] = 8'sd30;
        in_vec[3] = 8'sd40;
        valid_in  = 1;
        @(posedge clk); #1;
        valid_in = 0;
        @(posedge clk); #1;

        $display("Simulation outputs:");
        $display("  out[0] = %0d (expected %0d)", out_vec[0], EXP0);
        $display("  out[1] = %0d (expected %0d)", out_vec[1], EXP1);
        $display("  out[2] = %0d (expected %0d)", out_vec[2], EXP2);
        $display("  out[3] = %0d (expected %0d)", out_vec[3], EXP3);

        // ── Check results ─────────────────────────────────────────────────────
        if (out_vec[0] === EXP0) begin
            $display("PASS: out[0] = %0d", out_vec[0]); pass_count++;
        end else begin
            $display("FAIL: out[0] = %0d, expected %0d", out_vec[0], EXP0); fail_count++;
        end

        if (out_vec[1] === EXP1) begin
            $display("PASS: out[1] = %0d", out_vec[1]); pass_count++;
        end else begin
            $display("FAIL: out[1] = %0d, expected %0d", out_vec[1], EXP1); fail_count++;
        end

        if (out_vec[2] === EXP2) begin
            $display("PASS: out[2] = %0d", out_vec[2]); pass_count++;
        end else begin
            $display("FAIL: out[2] = %0d, expected %0d", out_vec[2], EXP2); fail_count++;
        end

        if (out_vec[3] === EXP3) begin
            $display("PASS: out[3] = %0d", out_vec[3]); pass_count++;
        end else begin
            $display("FAIL: out[3] = %0d, expected %0d", out_vec[3], EXP3); fail_count++;
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