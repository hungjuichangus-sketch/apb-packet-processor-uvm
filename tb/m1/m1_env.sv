class m1_env extends uvm_env;
    `uvm_component_utils(m1_env)

    apb_agent agt;
    m1_scoreboard scb;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = apb_agent::type_id::create("agt", this);
        scb = m1_scoreboard::type_id::create("scb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        agt.ap.connect(scb.apb_imp);
    endfunction
endclass
