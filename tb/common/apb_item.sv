class apb_item extends uvm_sequence_item;
    rand bit PWRITE;
    rand bit [11:0] PADDR;
    rand bit [31:0] PWDATA;
    bit [31:0] PRDATA;
    bit PREADY;
    bit PSLVERR;

    `uvm_object_utils_begin(apb_item)
        `uvm_field_int(PWRITE, UVM_ALL_ON)
        `uvm_field_int(PADDR, UVM_ALL_ON)
        `uvm_field_int(PWDATA, UVM_ALL_ON)
        `uvm_field_int(PRDATA, UVM_ALL_ON)
        `uvm_field_int(PREADY, UVM_ALL_ON)
        `uvm_field_int(PSLVERR, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "apb_item");
        super.new(name);
    endfunction
endclass
