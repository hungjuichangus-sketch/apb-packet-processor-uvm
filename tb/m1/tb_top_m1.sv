`include "uvm_macros.svh"
import uvm_pkg::*;
import m1_pkg::*;

module tb_top_m1();
    logic clk, rst_n;

    initial begin
        clk = 0;
        forever begin
            #5 clk = ~clk;
        end
    end

    initial begin
        rst_n = 0;
        repeat(3) @(posedge clk); #1;
        rst_n = 1;
    end

    apb_if aif(clk, rst_n);

    // M3 does not exist yet: the M1 inputs that come from M3 are tied to 0.
    logic        busy_i            = 0;
    logic        done_i            = 0;
    logic        format_ok_i       = 0;
    logic        length_error_i    = 0;
    logic        type_error_i      = 0;
    logic        chk_error_i       = 0;
    logic [5:0]  res_pkt_len_i     = 0;
    logic [7:0]  res_pkt_type_i    = 0;
    logic [7:0]  res_payload_sum_i = 0;
    logic [7:0]  res_payload_xor_i = 0;

    // M1 <-> M2 wires
    logic        pkt_mem_we;
    logic [2:0]  pkt_mem_addr;
    logic [31:0] pkt_mem_wdata;
    logic        pkt_mem_re;
    logic [31:0] pkt_mem_rdata;

    // DUT: M1 with M2 behind it
    apb_slave_if m1 (
        .PCLK              (clk),
        .PRESETn           (rst_n),
        .PSEL              (aif.PSEL),
        .PENABLE           (aif.PENABLE),
        .PWRITE            (aif.PWRITE),
        .PADDR             (aif.PADDR),
        .PWDATA            (aif.PWDATA),
        .PRDATA            (aif.PRDATA),
        .PREADY            (aif.PREADY),
        .PSLVERR           (aif.PSLVERR),
        .enable_o          (),
        .start_o           (),
        .algo_mode_o       (),
        .type_mask_o       (),
        .exp_pkt_len_o     (),
        .done_irq_en_o     (),
        .err_irq_en_o      (),
        .pkt_mem_we_o      (pkt_mem_we),
        .pkt_mem_addr_o    (pkt_mem_addr),
        .pkt_mem_wdata_o   (pkt_mem_wdata),
        .pkt_mem_re_o      (pkt_mem_re),
        .pkt_mem_rdata_i   (pkt_mem_rdata),
        .busy_i            (busy_i),
        .done_i            (done_i),
        .format_ok_i       (format_ok_i),
        .length_error_i    (length_error_i),
        .type_error_i      (type_error_i),
        .chk_error_i       (chk_error_i),
        .res_pkt_len_i     (res_pkt_len_i),
        .res_pkt_type_i    (res_pkt_type_i),
        .res_payload_sum_i (res_payload_sum_i),
        .res_payload_xor_i (res_payload_xor_i),
        .irq_o             ()
    );

    packet_sram m2 (
        .clk          (clk),
        .rst_n        (rst_n),
        .apb_wr_en    (pkt_mem_we),
        .apb_addr     (pkt_mem_addr),
        .apb_wr_data  (pkt_mem_wdata),
        .apb_rd_en    (pkt_mem_re),
        .apb_rd_data  (pkt_mem_rdata),
        .proc_rd_en   (1'b0),
        .proc_rd_addr (3'b0),
        .proc_rd_data ()
    );

    initial begin
        uvm_config_db #(virtual apb_if.DRV)::set(null, "*", "vif", aif.DRV);
        uvm_config_db #(virtual apb_if.MON)::set(null, "*", "vif", aif.MON);
        run_test();
    end
endmodule
