class m1_cfg_algo_mode_seq extends apb_base_seq;
    `uvm_object_utils(m1_cfg_algo_mode_seq)

    function new(string name = "m1_cfg_algo_mode_seq");
        super.new(name);
    endfunction

    task body();
        write(12'h004, 32'h0000_00F0);
        read(12'h004);
        write(12'h004, 32'h0000_00F1);
        read(12'h004);
    endtask
endclass
