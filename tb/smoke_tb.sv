// Phase 0 smoke test: proves compile -> simulate -> PASS/FAIL summary works.
// Convention used by every testbench in this project: print exactly one
// "TEST_PASS <name>" or "TEST_FAIL <name>" line; scripts/summarize.py counts them.
module smoke_tb;
    logic clk = 0;
    always #5 clk = ~clk;

    int cycles = 0;
    always @(posedge clk) cycles++;

    initial begin
        repeat (10) @(posedge clk);
        if (cycles >= 10) $display("TEST_PASS smoke_tb (cycles=%0d)", cycles);
        else              $display("TEST_FAIL smoke_tb (cycles=%0d)", cycles);
        $finish;
    end
endmodule
