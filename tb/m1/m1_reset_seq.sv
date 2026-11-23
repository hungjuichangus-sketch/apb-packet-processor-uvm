class m1_reset_seq extends apb_base_seq;
    `uvm_object_utils(m1_reset_seq)

    function new(string name = "apb_reset_seq");
        super.new(name);
    endfunction

    task body();
        read(12'h000);
        read(12'h004);
        read(12'h008);
    endtask
endclass
