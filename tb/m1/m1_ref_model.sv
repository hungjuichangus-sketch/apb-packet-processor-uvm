class m1_ref_model;
    logic enable;
    logic start;
    logic algo_mode;
    logic [3:0] type_mask;
    logic busy;
    logic done;
    logic error;
    logic format_ok;
    logic done_irq_en;
    logic err_irq_en;
    logic done_irq;
    logic err_irq;
    logic [5:0] exp_pkt_len;
    logic [5:0] res_pkt_len;
    logic [7:0] res_pkt_type;
    logic [7:0] res_payload_sum;
    logic [7:0] res_payload_xor;
    logic length_error;
    logic type_error;
    logic chk_error;

    localparam bit [11:0] CTRL            = 12'h000;
    localparam bit [11:0] CFG             = 12'h004;
    localparam bit [11:0] STATUS          = 12'h008;
    localparam bit [11:0] IRQ_EN          = 12'h00C;
    localparam bit [11:0] IRQ_STA         = 12'h010;
    localparam bit [11:0] PKT_LEN_EXP     = 12'h014;
    localparam bit [11:0] RES_PKT_LEN     = 12'h018;
    localparam bit [11:0] RES_PKT_TYPE    = 12'h01C;
    localparam bit [11:0] RES_PAYLOAD_SUM = 12'h020;
    localparam bit [11:0] RES_PAYLOAD_XOR = 12'h024;
    localparam bit [11:0] ERR_FLAG        = 12'h028;
    localparam bit [11:0] PKT_MEM_BASE    = 12'h040;
    localparam bit [11:0] PKT_MEM_END     = 12'h05C;

    function new();
        enable = 0;
        start = 0;
        algo_mode = 1;
        type_mask = 4'b1111;
        busy = 0;
        done = 0;
        error = 0;
        format_ok = 0;
        done_irq_en = 0;
        err_irq_en = 0;
        done_irq = 0;
        err_irq = 0;
        exp_pkt_len = 0;
        res_pkt_len = 0;
        res_pkt_type = 0;
        res_payload_sum = 0;
        res_payload_xor = 0;
        length_error = 0;
        type_error = 0;
        chk_error = 0;
    endfunction

    function void predict(apb_item item, output bit [31:0] exp_rdata, output bit exp_slverr);
        exp_rdata = 0;
        exp_slverr = 0;
        if(item.PADDR[1:0] != 0)begin
            exp_slverr = 1;
            return;
        end
        if(item.PWRITE)begin
            case(item.PADDR)
                CTRL:begin
                    enable = item.PWDATA[0];
                    start = item.PWDATA[1];
                end
                CFG:begin
                    algo_mode = item.PWDATA[0];
                    type_mask = item.PWDATA[7:4];
                end
                STATUS:begin
                    exp_slverr = 1;
                end
                IRQ_EN:begin
                    done_irq_en = item.PWDATA[0];
                    err_irq_en = item.PWDATA[1];
                end
                IRQ_STA:begin
                    if(item.PWDATA[0]) done_irq = 0;
                    if(item.PWDATA[1]) err_irq = 0;
                end
                PKT_LEN_EXP:begin
                    exp_pkt_len = item.PWDATA[5:0];
                end
                RES_PKT_LEN:begin
                    exp_slverr = 1;
                end
                RES_PKT_TYPE:begin
                    exp_slverr = 1;
                end
                RES_PAYLOAD_SUM:begin
                    exp_slverr = 1;
                end
                RES_PAYLOAD_XOR:begin
                    exp_slverr = 1;
                end
                ERR_FLAG:begin
                    exp_slverr = 1;
                end
                default: exp_slverr = 1;
            endcase
        end
        else begin
            case(item.PADDR)
                CTRL:begin
                    exp_rdata = {30'b0, 1'b0, enable};
                end
                CFG:begin
                    exp_rdata = {24'b0, type_mask, 3'b000, algo_mode};
                end
                STATUS:begin
                    exp_rdata = {28'b0, format_ok, error, done, busy};
                end
                IRQ_EN:begin
                    exp_rdata = {30'b0, err_irq_en, done_irq_en};
                end
                IRQ_STA:begin
                    exp_rdata = {30'b0, err_irq, done_irq};
                end
                PKT_LEN_EXP:begin
                    exp_rdata = {26'b0, exp_pkt_len};
                end
                RES_PKT_LEN:begin
                    exp_rdata = {26'b0, res_pkt_len};
                end
                RES_PKT_TYPE:begin
                    exp_rdata = {24'b0, res_pkt_type};
                end
                RES_PAYLOAD_SUM:begin
                    exp_rdata = {24'b0, res_payload_sum};
                end
                RES_PAYLOAD_XOR:begin
                    exp_rdata = {24'b0, res_payload_xor};
                end
                ERR_FLAG:begin
                    exp_rdata = {29'b0, chk_error, type_error, length_error};
                end
                default: exp_slverr = 1;
            endcase
        end
    endfunction
endclass
