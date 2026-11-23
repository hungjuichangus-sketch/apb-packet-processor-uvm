class m1_cfg_algo_mode_test extends m1_base_test;
    `uvm_component_utils(m1_cfg_algo_mode_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        apb_base_seq::type_id::set_type_override(m1_cfg_algo_mode_seq::get_type());
        super.build_phase(phase);
    endfunction
endclass
