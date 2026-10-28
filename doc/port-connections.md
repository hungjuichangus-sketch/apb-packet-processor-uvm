# PPA-Lite port connections (from spec §2.3, v1.02)

This is spec §2.3 with two added columns, **From** and **To**, so the block diagram can be drawn directly.
The spec file itself is left unchanged. Everything here is derived from §2.1–§2.3 and the module port tables.

Notation: `ext` = outside `ppa_top` (the APB master / the rest of the system). `Top.X` = a pin of `ppa_top`.

Port counts: **M1 = 33, M2 = 10, M3 = 19, ppa_top = 11**.

## ppa_top (11 ports)

| Dir | Signal | Width | From / To |
|---|---|---|---|
| in | PCLK | 1 | From ext. To M1.PCLK, M2.clk, M3.clk |
| in | PRESETn | 1 | From ext. To M1.PRESETn, M2.rst_n, M3.rst_n |
| in | PSEL | 1 | From ext (APB master). To M1.PSEL |
| in | PENABLE | 1 | From ext. To M1.PENABLE |
| in | PWRITE | 1 | From ext. To M1.PWRITE |
| in | PADDR | 12 | From ext. To M1.PADDR |
| in | PWDATA | 32 | From ext. To M1.PWDATA |
| out | PRDATA | 32 | From M1.PRDATA. To ext |
| out | PREADY | 1 | From M1.PREADY. To ext |
| out | PSLVERR | 1 | From M1.PSLVERR. To ext |
| out | irq_o | 1 | From M1.irq_o. To ext |

## M1 apb_slave_if (33 ports)

| Dir | Signal | Width | From / To |
|---|---|---|---|
| in | PCLK | 1 | From Top.PCLK |
| in | PRESETn | 1 | From Top.PRESETn |
| in | PSEL | 1 | From Top.PSEL |
| in | PENABLE | 1 | From Top.PENABLE |
| in | PWRITE | 1 | From Top.PWRITE |
| in | PADDR | 12 | From Top.PADDR |
| in | PWDATA | 32 | From Top.PWDATA |
| out | PRDATA | 32 | To Top.PRDATA |
| out | PREADY | 1 | To Top.PREADY (fixed 1) |
| out | PSLVERR | 1 | To Top.PSLVERR |
| out | enable_o | 1 | **No consumer in the spec** (M3 has no enable input). M1 uses it internally to gate `start`. Leave unconnected at the top |
| out | start_o | 1 | To M3.start_i |
| out | algo_mode_o | 1 | To M3.algo_mode_i |
| out | type_mask_o | 4 | To M3.type_mask_i |
| out | exp_pkt_len_o | 6 | To M3.exp_pkt_len_i |
| out | done_irq_en_o | 1 | **No consumer in the spec.** M1 uses it internally for the interrupt. Leave unconnected |
| out | err_irq_en_o | 1 | **No consumer in the spec.** Same as above |
| out | pkt_mem_we_o | 1 | To M2.apb_wr_en |
| out | pkt_mem_addr_o | 3 | To M2.apb_addr (shared by write and APB read) |
| out | pkt_mem_wdata_o | 32 | To M2.apb_wr_data |
| out | pkt_mem_re_o | 1 | To M2.apb_rd_en |
| in | pkt_mem_rdata_i | 32 | From M2.apb_rd_data |
| in | busy_i | 1 | From M3.busy_o |
| in | done_i | 1 | From M3.done_o |
| in | format_ok_i | 1 | From M3.format_ok_o |
| in | length_error_i | 1 | From M3.length_error_o |
| in | type_error_i | 1 | From M3.type_error_o |
| in | chk_error_i | 1 | From M3.chk_error_o |
| in | res_pkt_len_i | 6 | From M3.res_pkt_len_o |
| in | res_pkt_type_i | 8 | From M3.res_pkt_type_o |
| in | res_payload_sum_i | 8 | From M3.res_payload_sum_o |
| in | res_payload_xor_i | 8 | From M3.res_payload_xor_o |
| out | irq_o | 1 | To Top.irq_o |

## M2 packet_sram (10 ports)

| Dir | Signal | Width | From / To |
|---|---|---|---|
| in | clk | 1 | From Top.PCLK |
| in | rst_n | 1 | From Top.PRESETn |
| in | apb_wr_en | 1 | From M1.pkt_mem_we_o |
| in | apb_addr | 3 | From M1.pkt_mem_addr_o |
| in | apb_wr_data | 32 | From M1.pkt_mem_wdata_o |
| in | proc_rd_en | 1 | From M3.mem_rd_en_o |
| in | proc_rd_addr | 3 | From M3.mem_rd_addr_o |
| out | proc_rd_data | 32 | To M3.mem_rd_data_i |
| in | apb_rd_en | 1 | From M1.pkt_mem_re_o |
| out | apb_rd_data | 32 | To M1.pkt_mem_rdata_i |

## M3 packet_proc_core (19 ports)

| Dir | Signal | Width | From / To |
|---|---|---|---|
| in | clk | 1 | From Top.PCLK |
| in | rst_n | 1 | From Top.PRESETn |
| in | start_i | 1 | From M1.start_o |
| in | algo_mode_i | 1 | From M1.algo_mode_o |
| in | type_mask_i | 4 | From M1.type_mask_o |
| in | exp_pkt_len_i | 6 | From M1.exp_pkt_len_o |
| out | mem_rd_en_o | 1 | To M2.proc_rd_en |
| out | mem_rd_addr_o | 3 | To M2.proc_rd_addr |
| in | mem_rd_data_i | 32 | From M2.proc_rd_data |
| out | busy_o | 1 | To M1.busy_i |
| out | done_o | 1 | To M1.done_i |
| out | res_pkt_len_o | 6 | To M1.res_pkt_len_i |
| out | res_pkt_type_o | 8 | To M1.res_pkt_type_i |
| out | res_payload_sum_o | 8 | To M1.res_payload_sum_i |
| out | res_payload_xor_o | 8 | To M1.res_payload_xor_i |
| out | format_ok_o | 1 | To M1.format_ok_i |
| out | length_error_o | 1 | To M1.length_error_i |
| out | type_error_o | 1 | To M1.type_error_i |
| out | chk_error_o | 1 | To M1.chk_error_i |

## The same connections grouped as bundles (for the diagram)

| Bundle | Direction | Signals (width) | Count |
|---|---|---|---|
| **APB in** | ext → M1 | PSEL, PENABLE, PWRITE (1 each), PADDR (12), PWDATA (32) | 5 |
| **APB out** | M1 → ext | PRDATA (32), PREADY, PSLVERR (1 each) | 3 |
| **irq** | M1 → ext | irq_o (1) | 1 |
| **Clock / reset** | ext → M1, M2, M3 | PCLK, PRESETn (1 each, each fans out to 3 modules) | 2 |
| **A: write and APB-read path** | M1 → M2 | pkt_mem_we_o (1), pkt_mem_addr_o (3), pkt_mem_wdata_o (32), pkt_mem_re_o (1) | 4 |
| **B: APB read data** | M2 → M1 | apb_rd_data → pkt_mem_rdata_i (32) | 1 |
| **C: control** | M1 → M3 | start (1), algo_mode (1), type_mask (4), exp_pkt_len (6) | 4 |
| **D: status and results** | M3 → M1 | busy, done, format_ok, length_error, type_error, chk_error (1 each), res_pkt_len (6), res_pkt_type (8), res_payload_sum (8), res_payload_xor (8) | 10 |
| **E1: process read request** | M3 → M2 | mem_rd_en_o (1), mem_rd_addr_o (3) | 2 |
| **E2: process read data** | M2 → M3 | proc_rd_data → mem_rd_data_i (32) | 1 |
| **Unconnected at top** | M1 out | enable_o, done_irq_en_o, err_irq_en_o | 3 |

Check: M1 ports = 7 in (5 APB inputs + PCLK + PRESETn) + 3 out (APB) + 1 irq + 4 (A) + 1 (B) + 4 (C) + 10 (D) + 3 unconnected = 33. The unconnected ones are real ports of M1 and still belong in your diagram.
