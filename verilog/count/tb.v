// 测试模块：验证4位计数器功能
`timescale 1ns/1ns  // 仿真时间单位：1ns，精度：1ns

module tb_counter_4bit();

// 1. 定义测试信号（对应计数器的输入/输出）
reg         clk;      // 测试时钟
reg         rst_n;    // 测试复位
wire [3:0]  cnt;      // 计数器输出（wire类型，因为是模块输出）

// 2. 实例化待测试的计数器模块
counter_4bit u_counter_4bit(
    .clk    (clk),    // 时钟信号连接
    .rst_n  (rst_n),  // 复位信号连接
    .cnt    (cnt)     // 计数输出连接
);

// 3. 生成测试时钟（50MHz，周期20ns，10ns高、10ns低）
initial begin
    clk = 1'b0;       // 初始时钟低电平
    forever begin
        #10 clk = ~clk;  // 每10ns翻转一次，生成方波
    end
end

// 4. 生成复位信号和仿真控制
initial begin
    // 第一步：初始复位（低电平）
    rst_n = 1'b0;
    #25;               // 等待25ns（超过1个时钟周期）
    // 第二步：释放复位（高电平），开始计数
    rst_n = 1'b1;
    #300;              // 仿真300ns（足够计数到15并循环）
    // 第三步：结束仿真
    $stop;
end

// 5. 打印仿真结果（可选，方便观察）
initial begin
    $monitor("时间 = %0t ns, clk = %b, rst_n = %b, cnt = %b（十进制：%0d）",
             $time, clk, rst_n, cnt, cnt);
end

endmodule
