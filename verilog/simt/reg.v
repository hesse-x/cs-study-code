module reg_file(
    input clk,
    input rst_n,
    input we [0:common::THD_NUM-1],
    input [common::REG_ADDR_WIDTH-1:0] waddr [0:common::THD_NUM-1],
    input [common::DATA_WIDTH-1:0] wdata [0:common::THD_NUM-1],

    input [common::REG_ADDR_WIDTH-1:0] raddr1 [0:common::THD_NUM-1],
    input [common::REG_ADDR_WIDTH-1:0] raddr2 [0:common::THD_NUM-1],
    output reg [common::DATA_WIDTH-1:0] rdata1 [0:common::THD_NUM-1],
    output reg [common::DATA_WIDTH-1:0] rdata2 [0:common::THD_NUM-1]
);

reg [common::DATA_WIDTH-1:0] regs [0:common::REG_NUM-1];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // reset regs to 0.
        integer i;
        for(i = 0; i < common::REG_NUM; i = i + 1) begin
            regs[i] <= 32'd0;
        end
    end
    else begin
        // write data.
        integer i;
        for(i = 0; i < common::THD_NUM; i = i + 1) begin
            if (we[i]) begin
                regs[waddr[i]] <= wdata[i];
            end
        end
    end
end

always @(*) begin
    integer i;
    for(i = 0; i < common::THD_NUM; i = i + 1) begin
        rdata1[i] = regs[raddr1[i]];
        rdata2[i] = regs[raddr2[i]];
    end
end
endmodule
