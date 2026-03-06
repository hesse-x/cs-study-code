`timescale 1ns/1ns  // 仿真时间单位：1ns，精度：1ns
module tb_alu();

reg         clk;      // 测试时钟
reg         rst_n;    // 测试复位

// ---------------------- 新增：直接访问寄存器堆内部值 ----------------------
// 声明寄存器堆内部的regs数组（需与reg_file.v中的定义一致）
reg [31:0] regs [0:3];
reg [31:0] t [0:3];
reg [31:0] code;
// 实时读取寄存器堆的内部值（通过层次化路径）
always @(*) begin
    regs[0] = u_top.u_reg_file.regs[0];
    regs[1] = u_top.u_reg_file.regs[1];
    regs[2] = u_top.u_reg_file.regs[2];
    regs[3] = u_top.u_reg_file.regs[3];
    code = u_top.code;
end

// 实例化顶层模块
top u_top(
    .clk    (clk),    
    .rst_n  (rst_n)
);

initial begin
    // 1. 创建波形文件（tb_alu.vcd），所有工具都能识别
    $dumpfile("tb_alu.vcd");
    // 2. 导出层级：0表示导出tb_alu模块下的所有信号（包括子模块）
    $dumpvars(0, tb_alu);
end

// 生成时钟：10ns翻转一次，时钟周期20ns（频率50MHz）
initial begin
    clk = 1'b0;       
    forever begin
        #10 clk = ~clk;  
    end
end

// 仿真激励：按测试用例分步执行
initial begin
    rst_n = 1'b0;
    #10;               // 等待25ns（超过1个时钟周期）

    rst_n <= 1'b1;
    u_top.u_fetcher.u_mem.mem[0] <= 32'b0_01_00_01_0000000000011000000110100;
    u_top.u_fetcher.u_mem.mem[1] <= 32'b0_01_00_10_0000000000000000000000101;
    u_top.u_fetcher.u_mem.mem[2] <= 32'b0_00_00_11_01_10_000000000000000000000;
    u_top.u_fetcher.u_mem.mem[3] <= 32'b10000000000000000000000000000000;
    #120;               // 等待25ns（超过1个时钟周期）
    $stop;
end

// ---------------------- 优化打印：显示所有寄存器值 ----------------------
initial begin
    $monitor("时间 = %0t ns, clk = %b, rst_n = %b \n\t指令码 = %h \n\t寄存器值：r0=%d, r1=%d, r2=%d, r3=%d\n",
             $time, clk, rst_n, code,
             regs[0], regs[1], regs[2], regs[3]);
end

endmodule
