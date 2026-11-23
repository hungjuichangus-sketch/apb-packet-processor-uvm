class apb_base_seq extends uvm_sequence #(apb_item);
    `uvm_object_utils(apb_base_seq)

    apb_item item;

    function new(string name = "apb_base_seq");
        super.new(name);
    endfunction

    virtual task body();
    endtask

    task write(bit [11:0] addr, bit [31:0] wdata);
        item = apb_item::type_id::create("item");
        start_item(item);
        item.PWRITE = 1;
        item.PADDR = addr;
        item.PWDATA = wdata;
        finish_item(item);
    endtask

    task read(bit [11:0] addr);
        item = apb_item::type_id::create("item");
        start_item(item);
        item.PWRITE = 0;
        item.PADDR = addr;
        finish_item(item);
    endtask
endclass
