// M1: apb_slave_if -- APB 3.0 slave, all CSRs, PKT_MEM window control, IRQ.
// Spec: PPA-Lite requirements v1.02, sections 4 (APB), 5 (CSR), 6 (PKT_MEM), 8 (IRQ, PSLVERR).
// Design decisions D2..D16 are recorded in doc/design-decisions.md.
//
// APB timing used here (PREADY = 1, so every transfer is exactly SETUP + ACCESS):
//   write : everything takes effect at the clock edge that ends ACCESS.
//   read  : CSR data is a combinational mux of PADDR, valid in ACCESS.
//           PKT_MEM data comes from M2, which has 1-cycle read latency, so the
//           read enable is raised in SETUP and the data is valid in ACCESS.
//   PSLVERR is driven only during ACCESS (PSEL && PENABLE).

module apb_slave_if (
    input  logic        PCLK,
    input  logic        PRESETn,

    // APB slave
    input  logic        PSEL,
    input  logic        PENABLE,
    input  logic        PWRITE,
    input  logic [11:0] PADDR,
    input  logic [31:0] PWDATA,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    output logic        PSLVERR,

    // control / configuration to M3
    output logic        enable_o,
    output logic        start_o,
    output logic        algo_mode_o,
    output logic [3:0]  type_mask_o,
    output logic [5:0]  exp_pkt_len_o,
    output logic        done_irq_en_o,
    output logic        err_irq_en_o,

    // PKT_MEM access to M2
    output logic        pkt_mem_we_o,
    output logic [2:0]  pkt_mem_addr_o,
    output logic [31:0] pkt_mem_wdata_o,
    output logic        pkt_mem_re_o,
    input  logic [31:0] pkt_mem_rdata_i,

    // status and results from M3
    input  logic        busy_i,
    input  logic        done_i,
    input  logic        format_ok_i,
    input  logic        length_error_i,
    input  logic        type_error_i,
    input  logic        chk_error_i,
    input  logic [5:0]  res_pkt_len_i,
    input  logic [7:0]  res_pkt_type_i,
    input  logic [7:0]  res_payload_sum_i,
    input  logic [7:0]  res_payload_xor_i,

    output logic        irq_o
);

    // CSR word index = PADDR[11:2]
    localparam logic [9:0] A_CTRL         = 10'd0;    // 0x000
    localparam logic [9:0] A_CFG          = 10'd1;    // 0x004
    localparam logic [9:0] A_STATUS       = 10'd2;    // 0x008
    localparam logic [9:0] A_IRQ_EN       = 10'd3;    // 0x00C
    localparam logic [9:0] A_IRQ_STA      = 10'd4;    // 0x010
    localparam logic [9:0] A_PKT_LEN_EXP  = 10'd5;    // 0x014
    localparam logic [9:0] A_RES_PKT_LEN  = 10'd6;    // 0x018
    localparam logic [9:0] A_RES_PKT_TYPE = 10'd7;    // 0x01C
    localparam logic [9:0] A_RES_SUM      = 10'd8;    // 0x020
    localparam logic [9:0] A_RES_XOR      = 10'd9;    // 0x024
    localparam logic [9:0] A_ERR_FLAG     = 10'd10;   // 0x028

    assign PREADY = 1'b1;

    // ------------------------------------------------------------------
    // CSR storage
    // ------------------------------------------------------------------
    logic       enable_q;
    logic       algo_mode_q;
    logic [3:0] type_mask_q;
    logic       done_irq_en_q;
    logic       err_irq_en_q;
    logic [5:0] exp_pkt_len_q;
    logic       done_irq_q;
    logic       err_irq_q;
    logic       start_q;
    logic       done_q;         // previous done_i, for rising-edge detect
    logic       done_irq_now;   // flag including this cycle's event (see Interrupts below)
    logic       err_irq_now;

    assign enable_o      = enable_q;
    assign algo_mode_o   = algo_mode_q;
    assign type_mask_o   = type_mask_q;
    assign exp_pkt_len_o = exp_pkt_len_q;
    assign done_irq_en_o = done_irq_en_q;
    assign err_irq_en_o  = err_irq_en_q;
    assign start_o       = start_q;

    // ------------------------------------------------------------------
    // Address decode
    // ------------------------------------------------------------------
    logic [9:0] widx;
    logic       aligned;
    logic       is_pkt;         // 0x040..0x05F; with aligned: the 8 words 0x040..0x05C
    logic       csr_known;      // a defined CSR address
    logic       csr_writable;   // RW / W1P / RW1C
    logic [31:0] csr_rdata;
    logic       any_error;

    assign widx    = PADDR[11:2];
    assign aligned = (PADDR[1:0] == 2'b00);
    assign is_pkt  = (PADDR[11:5] == 7'b0000010);
    assign any_error = length_error_i | type_error_i | chk_error_i;

    always_comb begin
        csr_known    = 1'b0;
        csr_writable = 1'b0;
        csr_rdata    = 32'b0;
        case (widx)
            A_CTRL: begin
                csr_known    = 1'b1;
                csr_writable = 1'b1;
                csr_rdata    = {31'b0, enable_q};              // start (W1P) reads 0
            end
            A_CFG: begin
                csr_known    = 1'b1;
                csr_writable = 1'b1;
                csr_rdata    = {24'b0, type_mask_q, 3'b0, algo_mode_q};
            end
            A_STATUS: begin
                csr_known = 1'b1;
                csr_rdata = {28'b0, format_ok_i, any_error, done_i, busy_i};
            end
            A_IRQ_EN: begin
                csr_known    = 1'b1;
                csr_writable = 1'b1;
                csr_rdata    = {30'b0, err_irq_en_q, done_irq_en_q};
            end
            A_IRQ_STA: begin
                csr_known    = 1'b1;
                csr_writable = 1'b1;
                csr_rdata    = {30'b0, err_irq_now, done_irq_now};
            end
            A_PKT_LEN_EXP: begin
                csr_known    = 1'b1;
                csr_writable = 1'b1;
                csr_rdata    = {26'b0, exp_pkt_len_q};
            end
            A_RES_PKT_LEN: begin
                csr_known = 1'b1;
                csr_rdata = {26'b0, res_pkt_len_i};
            end
            A_RES_PKT_TYPE: begin
                csr_known = 1'b1;
                csr_rdata = {24'b0, res_pkt_type_i};
            end
            A_RES_SUM: begin
                csr_known = 1'b1;
                csr_rdata = {24'b0, res_payload_sum_i};
            end
            A_RES_XOR: begin
                csr_known = 1'b1;
                csr_rdata = {24'b0, res_payload_xor_i};
            end
            A_ERR_FLAG: begin
                csr_known = 1'b1;
                csr_rdata = {29'b0, chk_error_i, type_error_i, length_error_i};
            end
            default: ;
        endcase
    end

    // ------------------------------------------------------------------
    // Transfer phases
    // ------------------------------------------------------------------
    logic setup_phase;
    logic access_phase;
    logic wr_acc;               // the ACCESS cycle of a write

    assign setup_phase  = PSEL & ~PENABLE;
    assign access_phase = PSEL & PENABLE;
    assign wr_acc       = access_phase & PWRITE;

    // ------------------------------------------------------------------
    // PSLVERR (ACCESS phase only)
    //   misaligned, reserved, undefined          -> error
    //   write to a pure-RO CSR                   -> error (CTRL is W1P but also has RW enable, so it is writable)
    //   write to PKT_MEM while busy              -> error
    // ------------------------------------------------------------------
    logic err_cond;

    always_comb begin
        if (!aligned)       err_cond = 1'b1;
        else if (is_pkt)    err_cond = PWRITE & busy_i;
        else if (!csr_known) err_cond = 1'b1;
        else                err_cond = PWRITE & ~csr_writable;
    end

    assign PSLVERR = access_phase & err_cond;

    // ------------------------------------------------------------------
    // Read data
    // ------------------------------------------------------------------
    always_comb begin
        PRDATA = 32'b0;
        if (PSEL & ~PWRITE & aligned) begin
            if (is_pkt)         PRDATA = pkt_mem_rdata_i;
            else if (csr_known) PRDATA = csr_rdata;
        end
    end

    // ------------------------------------------------------------------
    // PKT_MEM path to M2
    //   write : in ACCESS, so M2 captures it at the edge that ends ACCESS
    //   read  : in SETUP, so M2's 1-cycle-latency data is ready in ACCESS
    // ------------------------------------------------------------------
    assign pkt_mem_addr_o  = PADDR[4:2];
    assign pkt_mem_wdata_o = PWDATA;
    assign pkt_mem_we_o    = wr_acc & aligned & is_pkt & ~busy_i;
    assign pkt_mem_re_o    = setup_phase & ~PWRITE & aligned & is_pkt;

    // ------------------------------------------------------------------
    // CSR writes
    // ------------------------------------------------------------------
    logic csr_wr;               // a valid write to a CSR (not PKT_MEM)
    logic start_acc;            // a legal start request
    logic clr_done_irq;
    logic clr_err_irq;

    assign csr_wr       = wr_acc & aligned & ~is_pkt & csr_known;
    // start is accepted only if enable was already 1 and M3 is not busy (D5, D14)
    assign start_acc    = csr_wr & (widx == A_CTRL) & PWDATA[1] & enable_q & ~busy_i;
    assign clr_done_irq = csr_wr & (widx == A_IRQ_STA) & PWDATA[0];
    assign clr_err_irq  = csr_wr & (widx == A_IRQ_STA) & PWDATA[1];

    // ------------------------------------------------------------------
    // Interrupts: set on the rising edge of done_i, "same beat" (D6, D15)
    //   *_now includes the event of this very cycle, so IRQ_STA and irq_o
    //   show the interrupt in the same cycle done_i first reads 1.
    // ------------------------------------------------------------------
    logic done_rise;
    logic set_done_irq;
    logic set_err_irq;

    assign done_rise    = done_i & ~done_q;
    assign set_done_irq = done_rise & done_irq_en_q;
    assign set_err_irq  = done_rise & any_error & err_irq_en_q;
    assign done_irq_now = done_irq_q | set_done_irq;
    assign err_irq_now  = err_irq_q  | set_err_irq;
    assign irq_o        = done_irq_now | err_irq_now;

    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            enable_q      <= 1'b0;
            algo_mode_q   <= 1'b1;
            type_mask_q   <= 4'b1111;
            done_irq_en_q <= 1'b0;
            err_irq_en_q  <= 1'b0;
            exp_pkt_len_q <= 6'b0;
            done_irq_q    <= 1'b0;
            err_irq_q     <= 1'b0;
            start_q       <= 1'b0;
            done_q        <= 1'b0;
        end else begin
            done_q  <= done_i;
            start_q <= start_acc;       // single-cycle pulse, one cycle after ACCESS

            // set wins over a simultaneous clear, so an event is never lost
            done_irq_q <= set_done_irq | (done_irq_q & ~clr_done_irq);
            err_irq_q  <= set_err_irq  | (err_irq_q  & ~clr_err_irq);

            if (csr_wr) begin
                case (widx)
                    A_CTRL:        enable_q <= PWDATA[0];
                    A_CFG: begin
                        algo_mode_q <= PWDATA[0];
                        type_mask_q <= PWDATA[7:4];
                    end
                    A_IRQ_EN: begin
                        done_irq_en_q <= PWDATA[0];
                        err_irq_en_q  <= PWDATA[1];
                    end
                    A_PKT_LEN_EXP: exp_pkt_len_q <= PWDATA[5:0];
                    default: ;          // RO registers: nothing is stored (PSLVERR reports it)
                endcase
            end
        end
    end

endmodule
