class m1_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(m1_scoreboard)
    uvm_analysis_imp #(apb_item, m1_scoreboard) apb_imp;
    m1_ref_model model;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        apb_imp = new("apb_imp", this);
        model = new();
    endfunction

    function void write(apb_item item);
        bit [31:0] exp_rdata;
        bit exp_slverr;
        model.predict(item, exp_rdata, exp_slverr);
        `uvm_info("SCB", $sformatf("%s addr=0x%03h wdata=0x%08h | act rdata=0x%08h slverr=%0b | exp rdata=0x%08h slverr=%0b",
            item.PWRITE ? "WR" : "RD", item.PADDR, item.PWDATA, item.PRDATA, item.PSLVERR, exp_rdata, exp_slverr), UVM_LOW)
        if(item.PRDATA != exp_rdata)
            `uvm_error("SCB", $sformatf("PRDATA mismatch: addr=0x%03h act=0x%08h exp=0x%08h", item.PADDR, item.PRDATA, exp_rdata))
        if(item.PSLVERR != exp_slverr)
            `uvm_error("SCB", $sformatf("PSLVERR mismatch: addr=0x%03h act=%0b exp=%0b", item.PADDR, item.PSLVERR, exp_slverr))
    endfunction
endclass
