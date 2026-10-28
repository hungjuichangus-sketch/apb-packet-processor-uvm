// M2: packet_sram -- 8 x 32-bit, 1 write port + 2 independent read ports.
// Spec: PPA-Lite requirements v1.02, sections 2.3 (M2 ports) and 6.3 (teaching hint 2).
//
//   write port : apb_wr_en / apb_addr / apb_wr_data           (from M1)
//   read port A: apb_rd_en / apb_addr   -> apb_rd_data         (to M1, APB read window)
//   read port B: proc_rd_en / proc_rd_addr -> proc_rd_data     (to M3, processing)
//
// No packet semantics here: M2 only stores and returns words.

module packet_sram (
    input  logic        clk,
    input  logic        rst_n,

    // write port (M1)
    input  logic        apb_wr_en,
    input  logic [2:0]  apb_addr,       // shared by the write and the APB read port
    input  logic [31:0] apb_wr_data,

    // read port B (M3)
    input  logic        proc_rd_en,
    input  logic [2:0]  proc_rd_addr,
    output logic [31:0] proc_rd_data,

    // read port A (M1 APB read window)
    input  logic        apb_rd_en,
    output logic [31:0] apb_rd_data
);

    logic [31:0] mem [8];

    always_ff @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            for(int i = 0; i < 8; i++)begin
                mem[i] <= 32'b0;
            end
            apb_rd_data <= 32'b0;
            proc_rd_data <= 32'b0;
        end else begin
            if(apb_wr_en)begin
                mem[apb_addr] <= apb_wr_data;
            end
            if(apb_rd_en)begin
                apb_rd_data <= mem[apb_addr];
            end
            if(proc_rd_en)begin
                proc_rd_data <= mem[proc_rd_addr];
            end
        end
    end

endmodule

//Q1 (contents after reset): zero. Why is that better than leaving the array undefined?
// Because leaving it undefined the device could has unpredictable reuslt.

//Q2 (rd_en=0): the output holds its last value.
//Why is that acceptable? Who is allowed to look at rd_data when rd_en was low?
// It's safe because rd_data is only meaningful when rd_en is high,
// although the reciver can see the rd_data value in every cycle, but they will
// ignore it when rd_en is low.

//Q3 (read and write the same address in the same cycle):
//the read returns the old value. Can that case happen with M1 and M3 in this design?
// Same channel wr/rd collide can't happen, because APB only allowed one at a time(PWRITE = 1)
// It could only happend in apb_wr, proc_rd, but only when you don't prevent it.
// You can use busy = 1 to prevent this.