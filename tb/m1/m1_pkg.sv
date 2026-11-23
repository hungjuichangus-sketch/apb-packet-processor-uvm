`include "uvm_macros.svh"

package m1_pkg;
    import uvm_pkg::*;
    import apb_pkg::*;

    `include "m1_ref_model.sv"
    `include "m1_scoreboard.sv"
    `include "m1_env.sv"
    `include "m1_reset_seq.sv"
    `include "m1_base_test.sv"
    `include "m1_reset_test.sv"
endpackage
