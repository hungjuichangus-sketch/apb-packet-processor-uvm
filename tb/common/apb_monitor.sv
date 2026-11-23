class apb_monitor extends uvm_monitor;
    `uvm_component_utils(apb_monitor)

    virtual apb_if.MON vif;
    apb_item item;
    uvm_analysis_port #(apb_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db #(virtual apb_if.MON)::get(this, "", "vif", vif))
            `uvm_fatal("MON", "Could not get interface from config db")
        ap = new("ap", this);
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            @(vif.mon_cb);
            if(vif.mon_cb.PSEL == 1 && vif.mon_cb.PENABLE == 1 && vif.mon_cb.PREADY == 1)begin
                item = apb_item::type_id::create("item");
                item.PWRITE = vif.mon_cb.PWRITE;
                item.PADDR = vif.mon_cb.PADDR;
                item.PWDATA = vif.mon_cb.PWDATA;
                item.PRDATA = vif.mon_cb.PRDATA;
                item.PSLVERR = vif.mon_cb.PSLVERR;
                ap.write(item);
            end
        end
    endtask
endclass
