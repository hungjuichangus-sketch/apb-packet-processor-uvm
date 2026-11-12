// Self-checking testbench for M1 (apb_slave_if), with M2 (packet_sram) behind it.
// M3 does not exist yet: this testbench drives the M3 side (busy_i, done_i, ...) itself.
// Convention: print exactly one TEST_PASS / TEST_FAIL line, then $finish.
//
// Layout (each section maps to a UVM role you will meet in Lab3):
//   1. signals + clock + DUT        -> interface
//   2. driver tasks                 -> driver
//   3. checker                      -> scoreboard
//   4. tests                        -> test / sequences
//   5. main sequence + final result
//
// Plan: doc/test-plan-m1.md. Name every check after its plan row, e.g. "B2 pin".
//
// Timing habit (same as packet_sram_tb): change inputs right AFTER a clock edge
// (@(posedge PCLK); #1), and sample outputs after the capturing edge (#1).

module apb_slave_if_tb;

    // ------------------------------------------------------------------
    // 1. Signals, clock, DUT
    // ------------------------------------------------------------------
    logic        PCLK = 0;
    logic        PRESETn;

    // APB side: you drive these, M1 reacts
    logic        PSEL;
    logic        PENABLE;
    logic        PWRITE;
    logic [11:0] PADDR;
    logic [31:0] PWDATA;
    // APB side: M1 drives these, you only sample
    logic [31:0] PRDATA;
    logic        PREADY;
    logic        PSLVERR;

    // M3 side: this testbench plays M3, so YOU drive these
    logic        busy_i;
    logic        done_i;
    logic        format_ok_i;
    logic        length_error_i;
    logic        type_error_i;
    logic        chk_error_i;
    logic [5:0]  res_pkt_len_i;
    logic [7:0]  res_pkt_type_i;
    logic [7:0]  res_payload_sum_i;
    logic [7:0]  res_payload_xor_i;

    // M1 outputs towards M3 and the outside: you only sample
    logic        enable_o;
    logic        start_o;
    logic        algo_mode_o;
    logic [3:0]  type_mask_o;
    logic [5:0]  exp_pkt_len_o;
    logic        done_irq_en_o;
    logic        err_irq_en_o;
    logic        irq_o;

    // M1 <-> M2 wires (internal, nobody drives them from the testbench)
    logic        pkt_mem_we_o;
    logic [2:0]  pkt_mem_addr_o;
    logic [31:0] pkt_mem_wdata_o;
    logic        pkt_mem_re_o;
    logic [31:0] pkt_mem_rdata_i;

    int errors = 0;     // number of mismatches
    int checks = 0;     // number of comparisons actually made

    always #5 PCLK = ~PCLK;

    apb_slave_if dut (.*);      // connects each port to the signal with the same name

    // M2 uses its own port names, so connect it by hand.
    // Its second (proc) read port belongs to M3, so it is tied off here.
    packet_sram m2 (
        .clk          (PCLK),
        .rst_n        (PRESETn),
        .apb_wr_en    (pkt_mem_we_o),
        .apb_addr     (pkt_mem_addr_o),
        .apb_wr_data  (pkt_mem_wdata_o),
        .apb_rd_en    (pkt_mem_re_o),
        .apb_rd_data  (pkt_mem_rdata_i),
        .proc_rd_en   (1'b0),
        .proc_rd_addr (3'b0),
        .proc_rd_data ()
    );

    // Watchdog: if the test hangs, fail instead of running forever.
    initial begin
        #1ms;
        $display("TEST_FAIL apb_slave_if_tb (timeout)");
        $finish;
    end

    // ------------------------------------------------------------------
    // 2. Driver tasks
    // ------------------------------------------------------------------

    // Put every DUT input at a known value (call this at time 0).
    task init_inputs();
        // TODO: APB inputs idle (PSEL, PENABLE, PWRITE low; PADDR, PWDATA 0)
        // TODO: every M3-side input (busy_i ... res_payload_xor_i) at 0
    endtask

    // Hold reset low for a few clocks, then release it just after an edge.
    task do_reset();
        // TODO
    endtask

    // One APB write: SETUP cycle, then ACCESS cycle, then back to idle.
    //   SETUP : PSEL=1, PENABLE=0, PWRITE=1, PADDR, PWDATA
    //   ACCESS: PENABLE=1  (PREADY is always 1, so ACCESS lasts exactly one cycle)
    // PSLVERR is only valid in the ACCESS cycle: capture it there.
    // Careful: PSLVERR depends on PENABLE through combinational logic, so after you
    // set PENABLE=1, wait #1 before sampling it (the same step is too early).
    task apb_write(input logic [11:0] addr, input logic [31:0] data, output logic pslverr);
        // TODO
    endtask

    // One APB read: same two phases, PWRITE=0. PRDATA and PSLVERR are valid in ACCESS.
    // For a PKT_MEM read, M2 has 1-cycle latency, but M1 starts it in SETUP,
    // so PRDATA is already right in ACCESS.
    task apb_read(input logic [11:0] addr, output logic [31:0] data, output logic pslverr);
        // TODO
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
    // 4. Tests (one task per plan row or group of rows)
    // ------------------------------------------------------------------

    // TODO: write your tests here, for example t_reset_values() for plan section A.

    // ------------------------------------------------------------------
    // 5. Main sequence and result
    // ------------------------------------------------------------------
    initial begin
        init_inputs();
        do_reset();

        // TODO: call your tests here

        // checks == 0 means no test did anything: that must NOT count as a pass.
        if (errors == 0 && checks > 0) $display("TEST_PASS apb_slave_if_tb (%0d checks)", checks);
        else                           $display("TEST_FAIL apb_slave_if_tb (%0d errors, %0d checks)", errors, checks);
        $finish;
    end

endmodule
