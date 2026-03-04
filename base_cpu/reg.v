// 寄存器堆：4个32位通用寄存器，2读1写，r0恒为0
module reg_file(
    input clk,                  // 时钟（仅写操作同步）
    input rst_n,                // 低有效复位
    input we,                   // 写使能（1=允许写，0=禁止写）
    input [1:0] waddr,          // 写地址（0-3，对应r0-r3）
    input [31:0] wdata,         // 写数据（来自ALU结果）
    input [1:0] raddr1,         // 读地址1
    input [1:0] raddr2,         // 读地址2
    output wire [31:0] rdata1,  // 读数据1（组合逻辑，异步）
    output wire [31:0] rdata2   // 读数据2（组合逻辑，异步）
);

// 内部存储阵列：4个32位寄存器（r0-r3）
reg [31:0] regs [0:3];

// 复位 + 同步写操作（clk上升沿触发）
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // 复位：所有寄存器清零（r0本来就是0）
        integer i;
        for(i = 0; i < 4; i = i + 1) begin
            regs[i] <= 32'd0;
        end
    end
    else begin
        // 写使能有效，且写地址不是r0（r0恒为0，禁止写）
        if (we && (waddr != 2'd0)) begin
            regs[waddr] <= wdata;
        end
    end
end

// 异步读操作（组合逻辑，地址变→数据立即变）
assign rdata1 = (raddr1 == 2'd0) ? 32'd0 : regs[raddr1];
assign rdata2 = (raddr2 == 2'd0) ? 32'd0 : regs[raddr2];

endmodule
