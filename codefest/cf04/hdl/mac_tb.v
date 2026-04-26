`timescale 1ns/1ps

module mac_tb;

    logic clk;
    logic rst;
    logic signed [7:0] a;
    logic signed [7:0] b;
    logic signed [31:0] out;

    mac dut (
        .clk(clk),
        .rst(rst),
        .a(a),
        .b(b),
        .out(out)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        a = 0;
        b = 0;

        @(posedge clk);
        #1;
        rst = 0;

        a = 8'sd3;
        b = 8'sd4;

        @(posedge clk);
        #1;
        $display("Cycle 1 output = %0d", out);

        @(posedge clk);
        #1;
        $display("Cycle 2 output = %0d", out);

        @(posedge clk);
        #1;
        $display("Cycle 3 output = %0d", out);

        rst = 1;
        @(posedge clk);
        #1;
        $display("After reset output = %0d", out);

        rst = 0;
        a = -8'sd5;
        b = 8'sd2;

        @(posedge clk);
        #1;
        $display("Negative cycle 1 output = %0d", out);

        @(posedge clk);
        #1;
        $display("Negative cycle 2 output = %0d", out);

        $finish;
    end

endmodule