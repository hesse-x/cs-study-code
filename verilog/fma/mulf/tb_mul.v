`timescale 1ns/1ns
module tb_mul();

reg         clk;
reg         rst_n;
reg [31:0] a;
reg [31:0] b;
reg [31:0] ret;

// 实例化顶层模块
mulf32 u_mul(
    .a(a), 
    .b(b),
    .prod(ret)
);

integer i;
initial begin
    $dumpfile("tb_mul.vcd");
    // 第一步：导出普通信号（标量/矢量）
    $dumpvars(0, tb_mul);
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
    #20;               // 等待25ns（超过1个时钟周期）

    rst_n <= 1'b1;
//    a <= 32'b0_01111111_00111010111000010100100;
    a <= 32'b0_01110111_00000110001001001101111;
    b <= 32'b0_01110111_00000110001001001101111;

    #20;
    $stop;
end

// ---------------------- 优化打印：显示所有寄存器值 ----------------------
initial begin
    $monitor({"时间 = %0t ns, clk = %b, rst_n = %b \n\tret = %h\n"},
             $time, clk, rst_n, ret,
   );
end
endmodule
