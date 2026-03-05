// 模块名：4位二进制加法计数器
// 功能：时钟上升沿计数，异步低复位，0~15循环
module counter_4bit(
    input           clk,      // 时钟信号（核心节拍器）
    input           rst_n,    // 异步复位信号（低电平有效）
    output reg [3:0] cnt      // 4位计数输出（reg对应触发器存储状态）
);

// 核心时序逻辑：时钟上升沿/复位下降沿触发状态更新
always @(posedge clk or negedge rst_n) begin
    // 第一步：处理复位（复位时计数归0）
    if(!rst_n) begin
        cnt <= 4'b0000;  // 复位：计数清零（4位二进制0）
    end
    // 第二步：正常计数（时钟上升沿）
    else begin
        // 计数到15（4'b1111）后，回到0，否则+1
        if(cnt == 4'd15) begin
            cnt <= 4'b0000;
        end else begin
            cnt <= cnt + 1'b1;  // 组合逻辑：计算下一个状态（+1）
        end
    end
end

endmodule
