# Design decisions

The specification (v1.02) leaves some behaviour open or contradicts itself in places. Each point is decided here, so the design and the testbenches agree and the choice can be defended.
Status: **DECIDED** means the RTL and the tests follow it. **OPEN** shows the current plan and will be settled when that module is written.

| ID | Question | Status and decision |
|---|---|---|
| D1 | Byte lane mapping of a 32-bit word | **DECIDED:** Byte0 = `[31:24]` (spec Appendix A) |
| D2 | PRDATA registered or combinational; the SRAM read must start in SETUP to return data in ACCESS | **DECIDED:** CSR read mux combinational; `pkt_mem_re_o` raised in SETUP; PRDATA is 0 outside a read transfer |
| D3 | Misaligned `PADDR[1:0]` not 0 | **DECIDED:** PSLVERR=1 with no side effect. Reason: §4.2 makes `0x05D`-`0x05F` an error, which "ignore the low bits" would contradict |
| D4 | §8.3 lists W1P as "read-only" for PSLVERR, but Appendix A writes CTRL=0x3 to start | **DECIDED:** PSLVERR only for pure-RO registers (STATUS, RES_*, ERR_FLAG) and reserved or undefined addresses. CTRL, CFG, IRQ_EN, IRQ_STA, PKT_LEN_EXP are writable |
| D5 | `start` written with `enable=0` or `busy=1` | **DECIDED:** silently ignored, PSLVERR=0 |
| D6 | IRQ "rising edge, same beat" | **DECIDED:** the flag is set at the edge ending the cycle where `done_i` first reads 1, and `IRQ_STA` / `irq_o` already show it in that same cycle (combinational term) |
| D7 | Words read and sum / XOR value when `pkt_len` is 0-3 or 33-255 | **OPEN:** clamp to at least 1 and at most 8 words; hold sum / XOR at 0 |
| D8 | `exp_pkt_len=0` means "not configured"? | **OPEN:** yes, the check is disabled |
| D9 | busy timing against the 1-cycle SRAM latency | **OPEN:** `busy_o=1` the cycle after `start_i` is sampled |
| D10 | Non-zero `flags` | **OPEN:** not checked |
| D11 | IDLE `done_o` wording differs between §7.2 and §7.4 | **OPEN:** IDLE is reachable only from reset, so `done_o=0` |
| D12 | M1 outputs `enable_o`, `done_irq_en_o`, `err_irq_en_o` have no consumer in the spec | **DECIDED:** used inside M1 only; left unconnected in `ppa_top` (see `doc/port-connections.md`) |
| D13 | When `PSLVERR` is driven | **DECIDED:** only in the ACCESS cycle (`PSEL && PENABLE`); 0 in SETUP and idle. Reads of reserved or undefined addresses also give PSLVERR=1 and PRDATA=0 |
| D14 | `start` with `enable` written in the same write (`CTRL=0x3` from reset) | **DECIDED:** `enable` is taken as its value **before** the write, so the first `0x3` does not start. Appendix A writes enable first, then start |
| D15 | `start_o` timing, and a set / clear collision on `IRQ_STA` | **DECIDED:** `start_o` is a registered 1-cycle pulse, one cycle after the ACCESS that accepted it. A simultaneous event and clear: the event wins |
| D16 | CFG / IRQ_EN / PKT_LEN_EXP writes while `busy=1` | **DECIDED:** allowed (the spec only restricts PKT_MEM) |

Documented typo in the specification: Appendix B.3 says the correct `hdr_chk` for `04_01_00_FF` is 0x00; it is 0x05. The conclusion (chk_error) still holds.
