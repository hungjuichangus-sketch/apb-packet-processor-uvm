class m1_reset_seq extends apb_base_seq;
    `uvm_object_utils(m1_reset_seq)

    apb_item item;

    function new(string name = "apb_reset_seq");
        super.new(name);
    endfunction

    task body();
        item = apb_item::type_id::create("item");
        start_item(item);
        item.PWRITE = 0;
        item.PADDR = 12'h000;
        item.PWDATA = 0;
        finish_item(item);

        item = apb_item::type_id::create("item");
        start_item(item);
        item.PWRITE = 0;
        item.PADDR = 12'h004;
        item.PWDATA = 0;
        finish_item(item);
    endtask
endclass
