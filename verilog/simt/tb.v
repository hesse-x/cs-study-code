`timescale 1ns/1ns
module tb_alu();

reg         clk;
reg         rst_n;

// 声明寄存器堆内部的regs数组（需与reg_file.v中的定义一致）
reg [common::DATA_WIDTH-1:0] regs [0:common::REG_NUM-1];
reg [common::CODE_WIDTH-1:0] code;
// 实时读取寄存器堆的内部值（通过层次化路径）
always @(*) begin
    integer i;
    for(i = 0; i < common::REG_NUM; i = i + 1) begin
        regs[i] = u_simt.u_reg_file.regs[i];
    end
end

// 实例化顶层模块
simt u_simt(
    .clk(clk),    
    .rst_n(rst_n),
    .code(code)
);

integer i;
initial begin
    $dumpfile("tb_alu.vcd");
    // 第一步：导出普通信号（标量/矢量）
    $dumpvars(0, tb_alu.clk, tb_alu.rst_n);
    
    // 第二步：显式导出数组的每个元素（关键！）
    // 导出code数组（2个元素）
    for(i=0; i<common::THD_NUM; i=i+1) begin
        $dumpvars(0, tb_alu.code);
        $dumpvars(0, tb_alu.u_simt.if2id_code);
        $dumpvars(0, tb_alu.u_simt.alu_en[i]);
        $dumpvars(0, tb_alu.u_simt.opcode[i]);
        $dumpvars(0, tb_alu.u_simt.rdata1[i]);
        $dumpvars(0, tb_alu.u_simt.rdata2[i]);
        $dumpvars(0, tb_alu.u_simt.alu_ret[i]);
        $dumpvars(0, tb_alu.u_simt.reg_we[i]);
        $dumpvars(0, tb_alu.u_simt.reg_wdata[i]);
    end
    // 导出寄存器堆数组（8个元素）
    for(i=0; i<common::REG_NUM; i=i+1) begin
        $dumpvars(0, tb_alu.u_simt.u_reg_file.regs[i]);
    end
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
    code <= 32'b0_01_00_01_0000000000011000000110100;
    #20;
    code <= 32'b0_01_00_10_0000000000000000000000101;
    #20;
    code <= 32'b0_00_00_11_01_10_000000000000000000000;
    #20;
    code <= 32'b10000000000000000000000000000000;
    #80;               // 等待25ns（超过1个时钟周期）
    $stop;
end

// ---------------------- 优化打印：显示所有寄存器值 ----------------------
initial begin
    $monitor({"时间 = %0t ns, clk = %b, rst_n = %b \n\t指令码 = %h\n",
             "groud0:\n\treg0: %d\n\treg1: %d\n\treg2: %d\n\treg3: %d\n",
             "groud1:\n\treg0: %d\n\treg1: %d\n\treg2: %d\n\treg3: %d\n"},
             $time, clk, rst_n, code,
             regs[0 * common::MAX_REG_NUM_PER_THD + 0],
             regs[0 * common::MAX_REG_NUM_PER_THD + 1],
             regs[0 * common::MAX_REG_NUM_PER_THD + 2],
             regs[0 * common::MAX_REG_NUM_PER_THD + 3],
             regs[1 * common::MAX_REG_NUM_PER_THD + 0],
             regs[1 * common::MAX_REG_NUM_PER_THD + 1],
             regs[1 * common::MAX_REG_NUM_PER_THD + 2],
             regs[1 * common::MAX_REG_NUM_PER_THD + 3]);
end
endmodule
