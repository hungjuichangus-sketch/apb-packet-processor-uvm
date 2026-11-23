class apb_driver extends uvm_driver #(apb_item);
    `uvm_component_utils(apb_driver)

    virtual apb_if.DRV vif;
    apb_item item;
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db #(virtual apb_if.DRV)::get(this, "", "vif", vif))
            `uvm_fatal("DRV", "Could not get the interface from config db")
    endfunction

    task run_phase(uvm_phase phase);
        reset();
        wait (vif.PRESETn == 1);
        @(vif.drv_cb);
        forever begin
            seq_item_port.get_next_item(item);
            @(vif.drv_cb); // SETUP
            vif.drv_cb.PSEL <= 1;
            vif.drv_cb.PWRITE <= item.PWRITE;
            vif.drv_cb.PADDR <= item.PADDR;
            vif.drv_cb.PWDATA <= item.PWDATA;
            @(vif.drv_cb); // ACCESS
            vif.drv_cb.PENABLE <= 1;
            @(vif.drv_cb);
            vif.drv_cb.PSEL <= 0;
            vif.drv_cb.PENABLE <= 0;
            seq_item_port.item_done();
        end
    endtask

    task reset();
        vif.drv_cb.PSEL <= 0;
        vif.drv_cb.PENABLE <= 0;
        vif.drv_cb.PWRITE <= 0;
        vif.drv_cb.PADDR <= 0;
        vif.drv_cb.PWDATA <= 0;
    endtask
endclass
