// Self-checking testbench for M2 (packet_sram).
// Convention: print exactly one TEST_PASS / TEST_FAIL line, then $finish.
//
// Layout (each section maps to a UVM role you will meet in Lab3):
//   1. signals + clock + DUT        -> interface
//   2. driver tasks                 -> driver
//   3. checker                      -> scoreboard
//   4. tests T1..T8                 -> test / sequences
//   5. main sequence + final result
//
// Timing habit: change inputs right AFTER a clock edge (@(posedge clk); #1),
// and sample outputs right after the NEXT edge (#1), to avoid races with the DUT.

module packet_sram_tb;

    // ------------------------------------------------------------------
    // 1. Signals, clock, DUT   (one signal per DUT port)
    // ------------------------------------------------------------------
    logic        clk = 0;
    logic        rst_n;

    logic        apb_wr_en;
    logic [2:0]  apb_addr;
    logic [31:0] apb_wr_data;
    logic        apb_rd_en;
    logic [31:0] apb_rd_data;

    logic        proc_rd_en;
    logic [2:0]  proc_rd_addr;
    logic [31:0] proc_rd_data;

    int errors = 0;     // number of mismatches
    int checks = 0;     // number of comparisons actually made

    always #5 clk = ~clk;

    packet_sram dut (.*);   // connects each port to the signal with the same name

    // Watchdog: if the test hangs, fail instead of running forever.
    initial begin
        #100us;
        $display("TEST_FAIL packet_sram_tb (timeout)");
        $finish;
    end

    // ------------------------------------------------------------------
    // 2. Driver tasks
    // ------------------------------------------------------------------

    // Put every DUT input at a known value (call this at time 0).
    task init_inputs();
        apb_wr_en = 0;
        apb_addr = 3'b0;
        apb_wr_data = 32'b0;
        apb_rd_en = 0;

        proc_rd_en = 0;
        proc_rd_addr = 3'b0;
    endtask

    // Hold reset low for a few clocks, then release it.
    task do_reset();
        rst_n = 0;
        repeat(3) @(posedge clk); #1;
        rst_n = 1;
    endtask

    // One write: drive wr_en/addr/data for one clock, then release.
    task write_word(input logic [2:0] addr, input logic [31:0] data);
        @(posedge clk); #1;
        apb_wr_en = 1;
        apb_addr = addr;
        apb_wr_data = data;
        @(posedge clk); #1;
        apb_wr_en = 0;
    endtask

    // One read on the APB port: drive rd_en/addr for one clock,
    // wait for the capturing edge, then sample apb_rd_data.
    task read_apb(input logic [2:0] addr, output logic [31:0] data);
        @(posedge clk); #1;
        apb_rd_en = 1;
        apb_addr = addr;
        @(posedge clk); #1;
        data = apb_rd_data;
        apb_rd_en = 0;
    endtask

    // Same, for the proc (M3) read port.
    task read_proc(input logic [2:0] addr, output logic [31:0] data);
        @(posedge clk); #1;
        proc_rd_en = 1;
        proc_rd_addr = addr;
        @(posedge clk); #1;
        data = proc_rd_data;
        proc_rd_en = 0;
    endtask

    // ------------------------------------------------------------------
    // 3. Checker
    // ------------------------------------------------------------------
    // Compare actual with expected; count it; print which check failed.
    task check_eq(input string what, input logic [31:0] actual, input logic [31:0] expected);
        checks++;
        if (actual !== expected) begin
            errors++;
            $display("MISMATCH %s: got %h, want %h", what, actual, expected);
        end
    endtask

    // ------------------------------------------------------------------
    // 4. Tests
    // ------------------------------------------------------------------

    // T1: after reset, all 8 words read back 0 through the APB port.
    task t1_reset_values();
        logic [31:0] got;
        for(int i = 0; i < 8; i++)begin
            read_apb(i, got);
            check_eq($sformatf("T1 word %0d", i), got, 32'b0);
        end
    endtask

    // T2: write 8 different values, read all back through the APB port.
    task t2_write_read_apb();
        logic [31:0] got;
        for (int i = 0; i < 8; i++) begin
            write_word(i, 32'hA000_0000 + i);
        end
        for (int i = 0; i < 8; i++) begin
            read_apb(i, got);
            check_eq($sformatf("T2 word %0d", i), got, 32'hA000_0000 + i);
        end
    endtask

    // T3: read the same 8 words through the proc port.
    task t3_read_proc();
        logic [31:0] got;
        for(int i = 0; i < 8; i++)begin
            read_proc(i, got);
            check_eq($sformatf("T3 word %0d", i), got, 32'hA000_0000 + i);
        end
    endtask

    // T4: both ports read different addresses in the same cycle.
    task t4_dual_read();
        logic [31:0] apb_got, proc_got;
        for(int i = 0; i < 8; i++)begin
            fork
                read_apb(i, apb_got);
                read_proc(7 - i, proc_got);
            join
            check_eq($sformatf("T4 apb word %0d", i), apb_got, 32'hA000_0000 + i);
            check_eq($sformatf("T4 proc word %0d", 7 - i), proc_got, 32'hA000_0000 + 7 - i);
        end
    endtask

    // T5: writing one word leaves its neighbours unchanged.
    task t5_neighbours();
        logic [31:0] got;
        write_word(3, 32'hFFFF_0000);
        for (int i = 0; i < 8; i++) begin
            read_apb(i, got);
            check_eq($sformatf("T5 word %0d", i), got,
                    (i == 3) ? 32'hFFFF_0000 : 32'hA000_0000 + i);
        end
    endtask

    // T6: latency. The data must NOT be there in the request cycle,
    //     and MUST be there after the capturing edge.
    task t6_latency();
        logic [31:0] got;
        write_word(2, 32'h1111_1111);
        write_word(5, 32'h5555_5555);
        read_apb(5, got);

        @(posedge clk); #1;
        apb_rd_en = 1;
        apb_addr = 2;
        #1;
        check_eq("T6 request cycle", apb_rd_data, 32'h5555_5555);

        @(posedge clk); #1;
        check_eq("T6 after capture", apb_rd_data, 32'h1111_1111);
        apb_rd_en = 0;
    endtask

    // T7: with rd_en = 0, the output holds its last value.
    task t7_hold();
        logic [31:0] got;
        write_word(1, 32'hAAAA_0001);
        write_word(6, 32'hBBBB_0006);
        read_apb(1, got);
        read_proc(1, got);

        apb_addr = 6;
        proc_rd_addr = 6;
        repeat(3) @(posedge clk);
        #1;
        check_eq("T7 apb hold", apb_rd_data, 32'hAAAA_0001);
        check_eq("T7 proc hold", proc_rd_data, 32'hAAAA_0001);
    endtask

    // T8: read and write the same address in the same cycle returns the OLD value.
    task t8_collision();
        logic [31:0] got;

        // case 1: APB write and APB read of word 4 in the same cycle
        write_word(4, 32'hAAAA_0004);       // old value
        @(posedge clk); #1;
        apb_wr_en   = 1;  apb_wr_data = 32'h5555_0004;   // new value
        apb_rd_en   = 1;  apb_addr    = 4;
        @(posedge clk); #1;                 // both are captured at this edge
        apb_wr_en = 0;  apb_rd_en = 0;
        check_eq("T8 apb read sees OLD", apb_rd_data, 32'hAAAA_0004);
        read_apb(4, got);
        check_eq("T8 write was kept",    got,         32'h5555_0004);

        // case 2: APB write and proc read of word 6 in the same cycle (the real M1 vs M3 clash)
        write_word(6, 32'hAAAA_0006);
        @(posedge clk); #1;
        apb_wr_en  = 1;  apb_wr_data = 32'h5555_0006;
        apb_addr   = 6;
        proc_rd_en = 1;  proc_rd_addr = 6;
        @(posedge clk); #1;
        apb_wr_en = 0;  proc_rd_en = 0;
        check_eq("T8 proc read sees OLD", proc_rd_data, 32'hAAAA_0006);
        read_proc(6, got);
        check_eq("T8 write was kept",     got,          32'h5555_0006);
    endtask

    // ------------------------------------------------------------------
    // 5. Main sequence and result
    // ------------------------------------------------------------------
    initial begin
        init_inputs();
        do_reset();

        t1_reset_values();
        t2_write_read_apb();
        t3_read_proc();
        t4_dual_read();
        t5_neighbours();
        t6_latency();
        t7_hold();
        t8_collision();

        // checks == 0 means no test did anything: that must NOT count as a pass.
        if (errors == 0 && checks > 0) $display("TEST_PASS packet_sram_tb (%0d checks)", checks);
        else                           $display("TEST_FAIL packet_sram_tb (%0d errors, %0d checks)", errors, checks);
        $finish;
    end

endmodule
