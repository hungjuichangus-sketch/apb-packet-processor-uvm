interface apb_if(input logic PCLK, PRESETn);
    logic PSEL;
    logic PENABLE;
    logic PWRITE;
    logic [11:0] PADDR;
    logic [31:0] PWDATA;
    logic [31:0] PRDATA;
    logic PREADY;
    logic PSLVERR;

    clocking drv_cb @(posedge PCLK);
        output PSEL, PENABLE, PWRITE, PADDR, PWDATA;
        input PRDATA, PREADY, PSLVERR;
    endclocking

    clocking mon_cb @(posedge PCLK);
        input PSEL, PENABLE, PWRITE, PADDR, PWDATA,
              PRDATA, PREADY, PSLVERR;
    endclocking

    modport DRV (clocking drv_cb,
                input PCLK, PRESETn);
    modport MON (clocking mon_cb,
                input PCLK, PRESETn);
endinterface

