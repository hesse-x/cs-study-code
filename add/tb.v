`timescale 1ns/1ns  // 仿真时间单位：1ns，精度：1ns
module tb_add();


reg         clk;      // 测试时钟
reg         rst_n;    // 测试复位
wire [31:0]  ret;      // 计数器输出（wire类型，因为是模块输出）
reg [31:0]   lhs;
reg [31:0]   rhs;

add u_add(
    .clk    (clk),    // 时钟信号连接
    .rst_n  (rst_n),  // 复位信号连接
    .lhs  (lhs),  // 复位信号连接
    .rhs  (rhs),  // 复位信号连接
    .ret    (ret)     // 计数输出连接
);

initial begin
    clk = 1'b0;       // 初始时钟低电平
    forever begin
        #10 clk = ~clk;  // 每10ns翻转一次，生成方波
    end
end

initial begin
    // 第一步：初始复位（低电平）
    rst_n = 1'b0;
    #25;               // 等待25ns（超过1个时钟周期）
    // 第二步：释放复位（高电平），开始计数
    rst_n = 1'b1;
    lhs <= 100;
    rhs <= 10;
    // 第三步：结束仿真
    #100;
    $stop;
end

initial begin
    $monitor("时间 = %0t ns, clk = %b, rst_n = %b, ret = %b（十进制：%0d）",
             $time, clk, rst_n, ret, ret);
end

endmodule
