# PPA-Lite Teaching Plan (v0.1)

Sources: the course description (v1.02) and the project requirements document (v1.02, 2026-04-24). Neither is included in this repository.
Spec terms are kept in the original Chinese/English wording of those documents.

## 1. Ground rules (agreed)

| Topic | Decision |
|---|---|
| Language | English explanations; original spec terms and SV/UVM keywords kept as written |
| Goal | Self-study, target **100/100 on every Lab** (3 mandatory + 2 optional items each), so the optional dependencies (Lab1 opt 4/5 → Lab3 opt 4/5 → Lab4 opt 5) all hold |
| Teaching style | **Coach:** you write the testbench; I give skeletons, hints, reviews, run simulations, explain waveforms. **Changed 2026-11-02:** I write the RTL for M1, M3 and `ppa_top` (you wrote M2); you verify them from the spec and the decision register, not by reading the RTL |
| License gap | **Hybrid:** labs run locally with `$urandom` stimulus and hand-rolled coverage counters; `randomize()` / `covergroup` are practised in short exercises on EDA Playground |
| No TA / course group | The course material comes from an open class, so there is no teaching assistant to ask. I am the only teacher and also play the TA in mock acceptances. Every spec gap in §6 is decided between us and written into the lab report |
| Coding style | 4 spaces per indent level in all SV code (Makefile recipes keep tabs) |
| Step size | Small steps. Concepts first, then a short task, then check questions. You asked to slow down (S1.1), so no new task starts until the concepts are clear to you |

Defaults I will assume unless you change them:

- **Pace:** mirror the course (about 2 weeks per Lab). One session is one focused sitting of about 1.5–2 h. No calendar dates until you tell me your weekly hours.
- **Testbench path:** plain class-based SV in Lab1–2, **UVM from Lab3**. UVM runs on the built-in library (1.1d, or 1.2 if we choose to switch).
- **Role rotation (Lab3):** with no partner, I write `ppa_top` or modules with planted bugs for you to find, and the reverse.
- **Version control:** a local git repo in this folder. Pushing to GitHub is your call.
- **Course slides:** if you have the course slides, put them in this folder so I can align the exam track with the real syllabus. I cannot see them otherwise.

## 2. Toolchain facts (verified 2026-10-27)

- Questa Altera Starter FPGA Edition 2025.2 at `C:\altera_lite\25.1std\questa_fse\win64`, on PATH (`vlib vlog vsim vcover qrun`).
- Works: classes, interfaces, clocking blocks, SVA (`assert` / `cover property`), mailbox / queue / associative array, UVM (1.1d built-in, 1.2 shipped), code coverage (branch, statement, FSM states and transitions, toggle), `.ucdb` save, `vcover report`.
- Blocked: `randomize()` and `covergroup` (`svverification` license not available). `$urandom` works. UVM sequence items must be filled by hand.
- `make` is `mingw32-make` (`C:\Users\user\mingw64\bin`). The Makefile will target it.
- Condition coverage also works (a "Conditions" line appears in `vcover report`; confirmed in Phase 0).

## 3. The loop used in every Lab

1. **Brief:** the SV/UVM concepts needed for this step, just in time.
2. **Decide:** settle the spec points listed in §6 for this step.
3. **Build:** you write RTL or testbench; I review against the spec.
4. **Debug:** waveform walk-through; you explain what you see.
5. **Mock acceptance:** I act as the TA and ask the §12.3 questions for each item (core check, secondary consistency, 驗收質量).
6. **Close:** report, commit, one-page "what I can now explain".

## 4. Curriculum

### Phase 0: Setup (1 session)

- Reading order of the spec (§2 → §4–6 → §7–9 → §10).
- Folder layout `rtl/ tb/ sim/ cov/ doc/`, Makefile with `smoke / regress / cov`, `sim/result_summary.txt` format.
- Questa flow by hand first (`vlib`, `vlog`, `vsim -c`, `vcover`), then wrapped in the Makefile.
- **Exit:** `make smoke` runs a hello-world simulation and writes the summary file.

### Lab1: M1 `apb_slave_if` + M2 `packet_sram` (about 5 sessions)

| Session | Content | New SV skills |
|---|---|---|
| S1.1 | APB 3.0 SETUP/ACCESS; field types RW / RO / W1P / RW1C; address arithmetic (`0x040 + 4N`); write M2 (8×32, 1 write / 2 read) | `logic`, `always_ff`, packed vs unpacked arrays |
| S1.2 | M1 part 1: transfer detect, address decoder, CTRL / CFG / IRQ_EN / PKT_LEN_EXP, RO pass-through | `enum`, `case`, `unique case`, parameters / localparams |
| S1.3 | M1 part 2: PKT_MEM write and read path, PSLVERR policy (opt 4), IRQ logic (opt 5) | combinational vs registered outputs, SV scheduling basics |
| S1.4 | Testbench: interface, clocking block, `apb_write` / `apb_read` tasks, SVA protocol checks, self-checking tests (CSR defaults, 8-word PKT_MEM, RES_* stub, PSLVERR, IRQ) | `interface`, `modport`, `clocking`, tasks, `assert property` |
| S1.5 | Makefile targets, first coverage look (confirm condition coverage works), mock acceptance, report | `vcover` basics |

**Exit gate:** all five items in §12.3 Lab1 demonstrable.

### Lab2: M3 `packet_proc_core` (about 5 sessions)

| Session | Content | New SV skills |
|---|---|---|
| S2.1 | FSM design, timing diagram on paper including 1-cycle SRAM latency; settle §6 Lab2 points | state-machine coding styles |
| S2.2 | M3 part 1: FSM, word counter, header extraction, length check, busy / done | `typedef enum`, counters |
| S2.3 | M3 part 2: type / type_mask check, hdr_chk and algo_mode, sum / XOR, error flags, result hold | bit slicing, reduction operators |
| S2.4 | Standalone testbench: behavioral SRAM array, packet class (pack, hdr_chk), reference model, scoreboard, `$urandom` packet generator; N-1…N-4, E-1…E-6 | classes, queues, mailbox, functions, `$urandom` |
| S2.5 | Waveform walk-through, mock acceptance, regress integration | debug with `vsim` GUI |

**EDA Playground exercise E1/E2:** constrained `randomize()` and a `covergroup` for the packet class.

### Lab3: `ppa_top` integration (about 6 sessions)

| Session | Content | New skills |
|---|---|---|
| S3.1 | Wiring (clock / reset fan-out, v1.02 M2 port names), integration testbench reusing Lab1 tasks, first end-to-end pass | hierarchical connection, `.*` |
| S3.2 | Bug-injection round: I plant bugs; you find them with your testbench | structured debug method |
| S3.3 | UVM foundations: phases, factory, `config_db`, objections; build the APB agent | `uvm_component`, `uvm_driver`, `uvm_monitor` |
| S3.4 | UVM env: scoreboard + predictor (reuse the Lab2 model); sequences for one frame and two frames; STATUS bus checks | `uvm_sequence`, TLM analysis ports |
| S3.5 | Optional items: busy-write PSLVERR (B-2), IRQ closed loop (B-3) | virtual sequences, assertions in env |
| S3.6 | Mock acceptance | |

**EDA Playground exercise E3:** a UVM sequence using `randomize()` on items.

### Lab4: regression and coverage closure (about 5 sessions)

| Session | Content |
|---|---|
| S4.1 | Map every Lab1–3 testcase to scenarios N / E / B; regression runner; seed strategy; `result_summary.txt` |
| S4.2 | Coverage baseline for the five types; `vcover merge`; HTML report; GUI review |
| S4.3 | Hole analysis, new tests, hand-rolled functional-coverage counters; exclusion file and the Excel filter register (opt 4) |
| S4.4 | testplan table, §12.4 engineering checklist, report front page |
| S4.5 | Defense rehearsal: regression results, coverage analysis, design decisions |

### Exam track (alongside every Lab, plus 2 sessions at the end)

| After | Topics |
|---|---|
| Lab1 | Data types, interfaces, clocking, scheduling regions and races, SVA basics |
| Lab2 | OOP (inheritance, polymorphism), constraints, mailbox / semaphore / event, functional coverage |
| Lab3 | UVM: phases, factory and overrides, `config_db`, TLM, sequence handshake, objections, reporting, register layer |
| Lab4 | Coverage-driven verification flow, testplan, regression |
| End | Two mock exams in the open-book format (multi-select + essay) |

## 5. Risks

- **Toggle coverage at 100%** in Lab4 is rarely reachable. The exclusion policy (opt 4) has to be planned early, not at the end.
- **Spec gaps with no authority to ask** (for example byte order). We decide each open point in §6 ourselves and record the decision and reason in the report, so the design is internally consistent and defensible.
- **License gap:** anything that needs `randomize()` or `covergroup` cannot be shown in the local Questa GUI.

## 6. Spec decision register

Decide each at the start of the stated session. "Lean" is my starting suggestion, not a decision.

| ID | Where | Question | Lean |
|---|---|---|---|
| D1 | S1.1 | Byte lane mapping of a 32-bit word | **DECIDED:** Byte0 = `[31:24]` (Appendix A) |
| D2 | S1.3 | PRDATA registered or combinational; SRAM read must start in SETUP to return data in ACCESS | **DECIDED:** CSR read mux combinational; `pkt_mem_re_o` raised in SETUP; PRDATA is 0 outside a read transfer |
| D3 | S1.2 | Misaligned `PADDR[1:0]≠0` | **DECIDED (changed from "ignore low bits"):** misaligned access returns PSLVERR=1 with no side effect. Reason: §4.2 makes `0x05D`–`0x05F` an error, which "ignore low bits" would contradict |
| D4 | S1.2 | §8.3 lists W1P as "read-only" for PSLVERR, but Appendix A writes CTRL=0x3 to start | **DECIDED:** PSLVERR only for pure-RO registers (STATUS, RES_*, ERR_FLAG) and reserved / undefined addresses. CTRL, CFG, IRQ_EN, IRQ_STA, PKT_LEN_EXP are writable |
| D5 | S1.2 | `start` written with `enable=0` or `busy=1` | **DECIDED:** silently ignored, PSLVERR=0 |
| D6 | S1.3 | IRQ "rising edge, same beat" | **DECIDED:** the flag is set at the edge ending the cycle where `done_i` first reads 1, and `IRQ_STA` / `irq_o` already show it in that same cycle (combinational term) |
| D7 | S2.1 | Words read and sum / XOR value when `pkt_len` is 0–3 or 33–255 | Clamp to at least 1 and at most 8 words; hold sum / XOR at 0; document it |
| D8 | S2.1 | `exp_pkt_len=0` means "not configured"? | Yes, check disabled |
| D9 | S2.1 | busy timing vs 1-cycle SRAM latency | `busy_o=1` the cycle after `start_i` is sampled |
| D10 | S2.3 | Non-zero `flags` | Not checked |
| D11 | S2.2 | IDLE `done_o` wording differs between §7.2 and §7.4 | IDLE is reachable only from reset, so `done_o=0` |
| D12 | S3.1 | M1 outputs `enable_o`, `done_irq_en_o`, `err_irq_en_o` have no consumer in the spec | Used inside M1 only; left unconnected in `ppa_top` (see `doc/port-connections.md`) |

Added while writing M1 (2026-11-02), all **DECIDED**:

| ID | Question | Decision |
|---|---|---|
| D13 | When is `PSLVERR` driven | Only in the ACCESS cycle (`PSEL && PENABLE`); 0 in SETUP and idle. Reads of reserved / undefined addresses also give PSLVERR=1 and PRDATA=0 |
| D14 | `start` with `enable` written in the same write (`CTRL=0x3` from reset) | `enable` is taken as its value **before** the write, so the first `0x3` does not start. Appendix A writes enable first, then start |
| D15 | `start_o` timing, and set/clear collision on `IRQ_STA` | `start_o` is a registered 1-cycle pulse, one cycle after the ACCESS that accepted it. A simultaneous event and clear: the event wins |
| D16 | CFG / IRQ_EN / PKT_LEN_EXP writes while `busy=1` | Allowed (spec only restricts PKT_MEM) |

Documented typo: Appendix B.3 says the correct `hdr_chk` for `04_01_00_FF` is 0x00; it is 0x05. The conclusion (chk_error) still holds.

## 7. Next step

Phase 0, session 1: project skeleton, Makefile, `make smoke`.
