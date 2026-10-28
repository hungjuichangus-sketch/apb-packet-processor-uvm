# PPA-Lite unified entry:  make smoke | make regress | make cov | make clean
# On this machine GNU make is installed as mingw32-make, so run e.g.:
#   mingw32-make smoke
# Recipes are kept cmd.exe-compatible (no sh on PATH).

WORK     := sim/work
WORK_COV := sim/work_cov

# Design and testbench sources; grows lab by lab.
RTL      := $(wildcard rtl/*.sv)
TB_SRC   := tb/smoke_tb.sv

# Every testbench top listed here is run by `make regress` / `make cov`.
TESTS    := smoke_tb

COV_TYPES := bcesfx

.PHONY: smoke regress cov clean FORCE

# --- smoke: fastest sanity check, one test ---------------------------------
smoke: sim/smoke_tb.log
	python scripts/summarize.py sim/smoke_tb.log

# --- regress: all tests in $(TESTS), then one PASS/FAIL summary -------------
regress: $(addprefix sim/,$(addsuffix .log,$(TESTS)))
	python scripts/summarize.py $^

# --- cov: rerun with code coverage, merge, report ---------------------------
define RUN_COV
vsim -c -lib $(WORK_COV) -coverage -voptargs="+cover=$(COV_TYPES)" $(1) -do "coverage save -onexit cov/$(1).ucdb; run -all; quit -f" > sim/$(1)_cov.log

endef

cov:
	vlib $(WORK_COV)
	vlog -sv -work $(WORK_COV) -cover $(COV_TYPES) $(RTL) $(TB_SRC)
	$(foreach t,$(TESTS),$(call RUN_COV,$(t)))
	vcover merge cov/merged.ucdb $(addprefix cov/,$(addsuffix .ucdb,$(TESTS)))
	vcover report -summary cov/merged.ucdb
	python scripts/summarize.py $(addprefix sim/,$(addsuffix _cov.log,$(TESTS)))

# --- plumbing ---------------------------------------------------------------
$(WORK)/_info: $(RTL) $(TB_SRC)
	vlib $(WORK)
	vlog -sv -work $(WORK) $(RTL) $(TB_SRC)

# FORCE makes every run re-simulate; compile only redoes when sources change.
sim/%.log: $(WORK)/_info FORCE
	vsim -c -lib $(WORK) $* -do "run -all; quit -f" > $@

clean:
	python -c "import shutil; [shutil.rmtree(p, ignore_errors=True) for p in ('sim/work','sim/work_cov')]"
	python -c "import glob, os; [os.remove(f) for f in glob.glob('sim/*.log')+glob.glob('sim/result_summary.txt')+glob.glob('cov/*.ucdb')+glob.glob('transcript')+glob.glob('*.wlf')]"

FORCE:
