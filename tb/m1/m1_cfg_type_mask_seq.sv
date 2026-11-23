class m1_cfg_type_mask_seq extends apb_base_seq;
    `uvm_object_utils(m1_cfg_type_mask_seq)

    function new(string name = "m1_cfg_type_mask_seq");
        super.new(name);
    endfunction

    task body();
        for(int i = 0; i < 16; i++)begin
            write(12'h004, {24'h0000_00, i, 4'b0});
            read(12'h004);
        end
    endtask
endclass
