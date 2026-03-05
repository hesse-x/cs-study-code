`timescale 1ns/1ns  // 仿真时间单位：1ns，精度：1ns
module tb_alu();

reg         clk;      // 测试时钟
reg         rst_n;    // 测试复位
reg  [31:0] code;     // 指令码

// ---------------------- 新增：直接访问寄存器堆内部值 ----------------------
// 声明寄存器堆内部的regs数组（需与reg_file.v中的定义一致）
reg [31:0] regs [0:3];
// 实时读取寄存器堆的内部值（通过层次化路径）
always @(*) begin
    regs[0] = u_top.u_reg_file.regs[0];
    regs[1] = u_top.u_reg_file.regs[1];
    regs[2] = u_top.u_reg_file.regs[2];
    regs[3] = u_top.u_reg_file.regs[3];
end

// 实例化顶层模块
top u_top(
    .clk    (clk),    
    .rst_n  (rst_n),  
    .code   (code)
);

initial begin
    // 1. 创建波形文件（tb_alu.vcd），所有工具都能识别
    $dumpfile("tb_alu.vcd");
    // 2. 导出层级：0表示导出tb_alu模块下的所有信号（包括子模块）
    $dumpvars(0, tb_alu);
    // 可选：指定导出的信号（精准导出，避免信号过多）
    // $dumpvars(1, tb_alu.clk, tb_alu.rst_n, tb_alu.code, tb_alu.ret);
    // $dumpvars(2, tb_alu.u_top.u_reg_file.regs); // 导出寄存器堆内部值
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
    // 第一步：初始复位（低电平）
    rst_n = 1'b0;
    code  = 32'd0;    // 初始指令无效
    #25;               // 等待25ns（超过1个时钟周期）

    // 第二步：执行立即数写入r1（值1234）
    rst_n <= 1'b1;
    // 指令码：0_11_01_000000000000000000011000000110100（12340）
    code  <= 32'b0_01_00_01_0000000000011000000110100;
    #40;  // 等待2个时钟周期（验证隔周期执行）

    // 第三步：执行立即数写入r2（值5）
    // 指令码：0_11_10_00000000000000011011110010101（5）
    code  <= 32'b0_01_00_10_0000000000000000000000101;
    #40;  // 等待2个时钟周期

    // 第四步：执行ALU加法（r3 = r1 + r2 = 1234+56789=58023）
    // 指令码：0_00_00_00_11_00000000000000000000
    code  <= 32'b0_00_00_11_01_10_000000000000000000000;
    #40;  // 等待2个时钟周期

    // 第五步：执行ALU减法（r3 = r2 - r1 = 56789-1234=55555）
    // 指令码：0_01_11_10_01_00000000000000000000
    // code  <= 32'b0_01_11_10_01_00000000000000000000;
    // #40;

    // 第六步：结束仿真
    $stop;
end

// ---------------------- 优化打印：显示所有寄存器值 ----------------------
initial begin
    $monitor("时间 = %0t ns, clk = %b, rst_n = %b \n\t指令码 = %h \n\t寄存器值：r0=%d, r1=%d, r2=%d, r3=%d \n",
             $time, clk, rst_n, code,
             regs[0], regs[1], regs[2], regs[3]);
end

endmodule
