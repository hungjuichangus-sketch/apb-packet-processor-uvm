class m1_base_test extends uvm_test;
    `uvm_component_utils(m1_base_test)

    m1_env env;
    apb_base_seq seq;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = m1_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        seq = apb_base_seq::type_id::create("seq");

        phase.raise_objection(this);
        seq.start(env.agt.sqr);
        phase.drop_objection(this);
    endtask
endclass
