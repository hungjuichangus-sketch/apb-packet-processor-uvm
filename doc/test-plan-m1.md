# Test plan: M1 `apb_slave_if`

Source: spec v1.02 sections 4, 5, 6, 8 and the decisions D2-D6, D13-D16 in `doc/design-decisions.md`.
Write this plan from the **spec only**. Do not read `rtl/apb_slave_if.sv` while writing tests.

## How to fill this plan

Every row is one thing the spec says the design must do. Your job is to prove it with a test.

| Column | Meaning |
|---|---|
| ID | A short name you can quote in the test and in failure messages |
| Feature | What the design must do, in plain words |
| Spec | Where the spec says it. `Dn` is a decision from the plan |
| How checked | What the test drives and what it compares |
| Test | The name of the testbench task that covers this row |
| Status | `TODO`, `WRITTEN`, `PASS`, `FAIL` |

Rule: a row is `PASS` only when a self-checking test that compares against an expected value from the spec passes. Running a line without checking its result does not count.

The rows below are empty on purpose. Add or delete rows freely; the IDs are only labels.

## Markdown table template

Rules: each row is one line; cells are separated by `|`; the second line (dashes) is required; no blank line inside the table.

```
| ID | Feature | Spec | How checked | Test | Status |
|---|---|---|---|---|---|
| X1 | One sentence on what must happen | 5.2 | Drive ..., expect ... | t_name | TODO |
```

Tips: write `\|` if you need a `|` inside a cell; keep cells short; put long notes below the table.

## Testbench environment note

For M1 tests the bench contains M1 and M2 connected as in `doc/port-connections.md`.
M3 does not exist yet, so **your testbench drives the M3 side directly**: `busy_i`, `done_i`, `format_ok_i`, `length_error_i`, `type_error_i`, `chk_error_i`, `res_*_i`.
That lets you create any M3 situation (error, done, busy) on demand.

## A. Reset values (spec 5.2)

| ID | Feature | Spec | How checked | Test | Status |
|---|---|---|---|---|---|
| A1 |After reset, CTRL reads 0 |5.2 |Reset, read 0x000, expect 32'h0| | Done |
| A2 |After reset, CFG reads 32'h0000_00F1 |5.2 |Reset, read 0x004 expect 32'h0000_00F1 | | Done |
| A3 |After reset, STATUS reads 0 |5.2 |Reset, read 0x008 expect 32'h0 | | Done |
| A4 | | | | | TODO |
| A5 | | | | | TODO |
| A6 | | | | | TODO |
| A7 | | | | | TODO |

## B. RW registers (spec 5.1, 5.2)

| ID | Feature | Spec | How checked | Test | Status |
|---|---|---|---|---|---|
| B1 |CFG[0],algo_mode bit is stored, readable, and appears on algo_mode_o |5.2 |Write CFG=32'h0000_00F0 (algo_mode=0, type_mask=1111): read 0x004, expect 32'h0000_00F0, and algo_mode_o=0 (sampled after the write has finished). Then write CFG=32'h0000_00F1: read, expect 32'h0000_00F1, and algo_mode_o=1 | | TODO |
| B2 |CFG[7:4], type_mask is stored and appears on type_mask_o |5.2 |For each ?=0-F (16 values): write CFG=32'h0000_00?0 (algo_mode=0 in every write), read 0x004, expect the same value, and type_mask_o equals ? (sampled after the write has finished) | | TODO |
| B3 | | | | | TODO |
| B4 | | | | | TODO |
| B5 | | | | | TODO |
| B6 | | | | | TODO |

## C. W1P: CTRL.start (spec 5.1, 5.2, D5, D14, D15)

| ID | Feature | Spec | How checked | Test | Status |
|---|---|---|---|---|---|
| C1 |start reads 0 and stores nothing(W1P) |5.1 |Write 1 to 0x000's bit 1(CTRL[1]), and reads it bit 1 should be 0 | | TODO |
| C2 |Accepted start(enable=1 && busy_i=0) gives start_o a pulse |5.2 |After Enable, write CTRL=0x3, a pulse on start_o | | TODO |
| C3 |The pulse last exactly one cycle |5.1 |Sample start_o every cycle after the write, count the high cycle:1 | | TODO |
| C4 |With enable=0, start is rejected |5.2 |With enable=0, write CTRL=0x2 (enable=0, start=1): no start_o pulse | | TODO |
| C5 |With busy_i=1, a start is rejected |5.2 |With enable=1, drive busy_i=1, write CTRL=0x3, no pulse for start_o | | TODO |
| C6 |A rejected start gives PSLVERR=0 |D5 |In C4, C5 check PSLVERR is 0 | | TODO |
| C7 |With enable=1 and busy_i=0, writing CTRL with start=0 never pulses start_o |5.1 |First write CTRL=0x3 and see one pulse (proves a start would be accepted). Then write CTRL=0x1 (enable=1, start=0): no pulse. Then write CTRL=0x0 (enable=0, start=0): no pulse | | TODO |
| C8 |Two accepted starts give two separate pulses |5.2 |enable=1 and busy_i=0 throughout. Write CTRL=0x3, wait a few idle cycles, write CTRL=0x3 again. Count 2 pulses, each 1 cycle long | | TODO |
| C9 |Enable and start written in one write, from enable=0:not started |D14 |Reset, write 0x3 once, no pulse; write 0x3 again, pulse | | TODO |

## D. RO registers and status pass-through (spec 5.1, 5.2, 8.3)

| ID | Feature | Spec | How checked | Test | Status |
|---|---|---|---|---|---|
| D1 | | | | | TODO |
| D2 | | | | | TODO |
| D3 | | | | | TODO |
| D4 | | | | | TODO |
| D5 | | | | | TODO |
| D6 | | | | | TODO |

## E. Interrupts and RW1C IRQ_STA (spec 5.1, 8.2, D6, D15)

| ID | Feature | Spec | How checked | Test | Status |
|---|---|---|---|---|---|
| E1 | | | | | TODO |
| E2 | | | | | TODO |
| E3 | | | | | TODO |
| E4 | | | | | TODO |
| E5 | | | | | TODO |
| E6 | | | | | TODO |
| E7 | | | | | TODO |
| E8 | | | | | TODO |
| E9 | | | | | TODO |
| E10 | | | | | TODO |
| E11 | | | | | TODO |
| E12 | | | | | TODO |
| E13 | | | | | TODO |

## F. Address map and PSLVERR (spec 4.2, 8.3, D3, D13)

| ID | Feature | Spec | How checked | Test | Status |
|---|---|---|---|---|---|
| F1 | | | | | TODO |
| F2 | | | | | TODO |
| F3 | | | | | TODO |
| F4 | | | | | TODO |
| F5 | | | | | TODO |
| F6 | | | | | TODO |
| F7 | | | | | TODO |

## G. PKT_MEM window (spec 6, D2)

| ID | Feature | Spec | How checked | Test | Status |
|---|---|---|---|---|---|
| G1 | | | | | TODO |
| G2 | | | | | TODO |
| G3 | | | | | TODO |
| G4 | | | | | TODO |
| G5 | | | | | TODO |
| G6 | | | | | TODO |
| G7 | | | | | TODO |
| G8 | | | | | TODO |
| G9 | | | | | TODO |
| G10 | | | | | TODO |

## H. APB protocol behaviour (spec 4.1)

| ID | Feature | Spec | How checked | Test | Status |
|---|---|---|---|---|---|
| H1 | | | | | TODO |
| H2 | | | | | TODO |
| H3 | | | | | TODO |
| H4 | | | | | TODO |
| H5 | | | | | TODO |
| H6 | | | | | TODO |

## I. Rows that fit nowhere above

| ID | Feature | Spec | How checked | Test | Status |
|---|---|---|---|---|---|
| I1 | | | | | TODO |
| I2 | | | | | TODO |

## J. For later (not testable on M1 alone)

| ID | What the spec says | Why not M1 | Test it in |
|---|---|---|---|
| J1 | algo_mode=0 skips hdr_chk and forces chk_error=0 | M3 does the check | Lab2, M3 plan |
| J2 | type_mask blocks pkt_type values; mask 0000 rejects every type | M3 does the check | Lab2, M3 plan |
| J3 | After an accepted start, STATUS.busy becomes 1 | busy comes from M3 | Lab3, integration |

## Suggested order for writing the tests

1. The APB `apb_write` / `apb_read` tasks (they return PSLVERR too).
2. Section A, then B, then D (simple register checks).
3. Section F and G (addresses and memory, needs M2 in the bench).
4. Section C and E (start pulse and interrupts: they need cycle-level checks).
5. Section H last (protocol timing, a good place to add SVA assertions).

Add one `check_eq` per expected value, with a name that includes the row ID, for example `check_eq("B4 exp_pkt_len", got, 32'h3F)`.
