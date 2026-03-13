`timescale 1ns/1ns
module tb_add();

reg         clk;
reg         rst_n;
reg [31:0] a;
reg [31:0] b;
wire [31:0] ret;
wire [7:0] a_exp;
wire [24:0] a_mant;
wire [7:0] b_exp;
wire [24:0] b_mant;
wire [24:0] mant_sum;
wire [7:0] exp_norm;
wire [24:0] mant_large;
wire [24:0] mant_small;
wire [24:0] mant_small_shifted;
wire [24:0] mant_norm;
wire [7:0] pad_exp_diff;
wire [7:0] exp_large;

assign a_exp = u_add.a_exp;
assign b_exp = u_add.b_exp;
assign a_mant = u_add.a_mant;
assign b_mant = u_add.b_mant;
assign mant_sum = u_add.mant_sum;
assign exp_norm = u_add.exp_large + u_add.exp_rectification;
assign mant_large = u_add.mant_large;
// assign mant_small = u_add.mant_small;
assign mant_small_shifted = u_add.mant_small_shifted;
assign mant_norm = u_add.mant_norm;
assign pad_exp_diff = u_add.pad_exp_diff;
assign exp_large = u_add.exp_large;

// 实例化顶层模块
addf u_add(
    .a(a), 
    .b(b),
    .sum(ret)
);

integer i;
initial begin
    $dumpfile("tb_add.vcd");
    // 第一步：导出普通信号（标量/矢量）
    $dumpvars(0, tb_add);
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

    a <= 32'b0_01111111_00111010111000010100100;
    b <= 32'b0_01110111_00000110001001001101111;
    #20;

    a <= 32'b0_01111111_00111010111000010100100;
    b <= 32'b0_01111111_00111010111000010100100;
    #20;


    a <= 32'b0_01111111_00111010111000010100100;
    b <= 32'b1_01111110_00111010111000010100100;
    #20;
    $stop;
end

// ---------------------- 优化打印：显示所有寄存器值 ----------------------
initial begin
    $monitor({"时间 = %0t ns, clk = %b, rst_n = %b \n\tret = %h\n\ta_exp = %08b, b_exp = %08b",
              "a_mant = %24b, b_mant = %24b, exp_norm = %08b, mant_sum = %24b, ",
              "mant_large = %24b, mant_small = %24b, mant_small_shifted = %24b, ",
              "mant_norm=%24b, pad_exp_diff=%08b, exp_large=%08b"},
             $time, clk, rst_n, ret, a_exp, b_exp, a_mant, b_mant, exp_norm, mant_sum, mant_large, mant_small, mant_small_shifted, mant_norm, pad_exp_diff, exp_large
   );
end
endmodule
