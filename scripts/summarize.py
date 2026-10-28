"""Count TEST_PASS / TEST_FAIL lines in the given log files and write
sim/result_summary.txt.

Usage: python scripts/summarize.py sim/a.log sim/b.log ...

Exit code is 1 if any test failed or no test result was found, so `make`
stops on a bad run.
"""
import re
import sys

passed, failed = [], []
for log in sys.argv[1:]:
    with open(log, encoding="utf-8", errors="replace") as f:
        for line in f:
            m = re.search(r"TEST_(PASS|FAIL)\s+(\S+)", line)
            if m:
                (passed if m.group(1) == "PASS" else failed).append(m.group(2))

lines = [
    f"PASS_COUNT: {len(passed)}",
    f"FAIL_COUNT: {len(failed)}",
    f"RESULT: {'PASS' if passed and not failed else 'FAIL'}",
]
lines += [f"FAILED: {n}" for n in failed]

with open("sim/result_summary.txt", "w", encoding="utf-8") as f:
    f.write("\n".join(lines) + "\n")
print("\n".join(lines))
sys.exit(0 if passed and not failed else 1)
