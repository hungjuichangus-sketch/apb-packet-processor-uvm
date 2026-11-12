# APB Packet Processor: SystemVerilog / UVM verification

A self-study design verification project. The design is **PPA-Lite** (APB Packet Processing Accelerator Lite), a small accelerator that software controls over an APB 3.0 bus: software writes one data packet into an on-chip buffer, configures registers, starts the hardware, and reads back the result (header checks, payload sum and XOR) and an interrupt.

The goal of this repository is the **verification**: test plans, self-checking testbenches, a reusable UVM agent, block-level and top-level environments, and coverage.

## Design

| Module | Role |
|---|---|
| `apb_slave_if` (M1) | APB 3.0 slave, all control and status registers, PKT_MEM window control, interrupt logic |
| `packet_sram` (M2) | 8 x 32-bit memory with one write port and two read ports (1-cycle read latency) |
| `packet_proc_core` (M3) | 3-state FSM that reads the packet, checks the header, computes sum and XOR (not written yet) |
| `ppa_top` | Wiring only (not written yet) |

Port connections are in `doc/port-connections.md`. Behaviour that the specification leaves open, and the choice made for each point, is in `doc/design-decisions.md`.

## Status

| Item | State |
|---|---|
| M2 `packet_sram` RTL and flat self-checking testbench (8 tests, 56 checks) | Done |
| M1 `apb_slave_if` RTL | Written, quick sanity-checked only |
| M1 test plan (`doc/test-plan-m1.md`) | In progress |
| M1 testbench (flat skeleton, then UVM) | Not started |
| UVM environment (`tb/common`, `tb/m1`, `tb/top`) | Empty file layout only |
| M3, `ppa_top`, top-level verification, coverage closure | Not started |

## Layout

```
rtl/        design (M1, M2)
tb/         testbenches
  common/   reusable APB UVM agent (planned)
  m1/       M1 block environment (planned)
  top/      top-level environment (planned)
doc/        port connections, test plans
scripts/    result summary script used by the Makefile
Makefile    smoke / regress / cov / clean
```

## Running

Needs Questa (developed with Questa Altera Starter FPGA Edition 2025.2), GNU make and Python. The Starter edition has no license for `randomize()` and `covergroup`, so the local flow uses `$urandom` and hand-written coverage counters; code coverage works.

```
mingw32-make smoke      # fastest check
mingw32-make regress    # every test, then one PASS/FAIL summary
mingw32-make cov        # rerun with code coverage and merge
```

On other setups, replace `mingw32-make` with `make`. Each test prints one `TEST_PASS` or `TEST_FAIL` line, and `scripts/summarize.py` counts them.

## Credits and AI assistance

- The project is the final lab of an open SV/UVM verification course by RockerIC and the School of Microelectronics at Xidian University. The course's public code repository is https://github.com/rockeric/rkv_v1pro_labs. The course's specification documents are not included here.
- The course encourages AI programming tools. In this repository, **the RTL design of M1 (and of M3 and the top level when they are added) is done by AI from the specification. The author verifies it against the same specification, without reading the RTL code.** Verifying from the specification keeps the checks independent: a misreading of the spec in the RTL is not copied into the testbench.
- The author's own work is the M2 RTL and its testbench, the test plans, the testbenches and the UVM environments.
