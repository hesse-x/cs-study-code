module reg_file(
    input clk,                  // 时钟（仅写操作同步）
    input rst_n,                // 低有效复位
    input we,                   // 写使能（1=允许写，0=禁止写）
    input [1:0] waddr,          // 写地址（0-3，对应r0-r3）
    input [31:0] wdata,         // 写数据（来自ALU结果）
    input [1:0] raddr1,         // 读地址1
    input [1:0] raddr2,         // 读地址2
    output wire [31:0] rdata1,  // 读数据1（组合逻辑，异步）
    output wire [31:0] rdata2  // 读数据2（组合逻辑，异步）
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
        if (we) begin
          if (waddr != 2'd0) begin
            regs[waddr] <= wdata;
          end
        end
    end
end

// 异步读操作（组合逻辑，地址变→数据立即变）
assign rdata1 = (raddr1 == 2'd0) ? 32'd0 : regs[raddr1];
assign rdata2 = (raddr2 == 2'd0) ? 32'd0 : regs[raddr2];

endmodule
module mem(
    input clk,                  // 时钟（仅写操作同步）
    input [31:0] addr,
    output wire [31:0] data
);

reg [31:0] mem [0:8];
assign data = mem[addr];

endmodule

// 取指单元：PC发生器 + 指令存储器（IMEM）
module fetcher(
    input clk,
    input rst_n,
    input flush,          // 流水线冲刷信号（高有效）
    output [31:0] inst    // 取出的指令（送IF级锁存）
);

reg [31:0] pc;
mem u_mem(
    .clk(clk),
    .addr(pc),
    .data(inst)
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pc <= 0;
    end else begin
      if (inst[31] != 1) begin
          pc <= pc + 1;
      end
    end
end


endmodule
// code[31]    ：指令有效位（1=无效，0=有效）
// code[30:29] ：指令类型（optype）
//               00=ALU运算指令 | 01=立即数写入指令 
//               10=跳转指令（预留） | 11=访存指令（预留）
// code[28:27] ：操作子类型（opcode）- 不同指令类型下含义不同
//               ALU指令：00=add | 01=sub | 10=mul | 11=div
//               其他指令：预留
// code[26:25] ：写寄存器地址（waddr）- 所有写指令共用
// code[24:23] ：读寄存器地址1（raddr1）- ALU/访存指令用
// code[22:21] ：读寄存器地址2（raddr2）- ALU指令用
// code[20:0]   ：指令参数（立即数/跳转地址/访存地址等）
module decoder(
    input clk,
    input rst_n,
    input [31:0] code,
    output reg alu_en,       // ALU运算指令使能
    output reg [1:0] opcode, // 运算类型（仅ALU指令有效）
    // 寄存器读地址（仅ALU指令有效）
    output reg [1:0] raddr1,
    output reg [1:0] raddr2,
    // 写寄存器地址（ALU/立即数指令共用）
    output reg [1:0] waddr,
    output reg we,           // 通用写使能
    output reg imm_en,       // 立即数写入指令使能
    output reg [31:0] imm_data // 立即数数据
);

// 本地参数：仅内部使用，不修改外部接口
localparam OPTYPE_ALU    = 2'b00;  // ALU指令（code[30:29]）
localparam OPTYPE_IMM    = 2'b01;  // 立即数指令（code[30:29]）

always @(*) begin
    // ==============================================
    // 步骤1：赋默认值（杜绝锁存器，所有信号先清零）
    // ==============================================
    alu_en    = 1'b0;
    opcode    = 2'b00;
    raddr1    = 2'd0;
    raddr2    = 2'd0;
    waddr     = 2'd0;
    we        = 1'b0;
    imm_en    = 1'b0;
    imm_data  = 32'd0;

    // ==============================================
    // 步骤2：复位判断（复位时保持默认值）
    // ==============================================
    if (rst_n) begin
        // ==============================================
        // 步骤3：指令有效性判断（code[31]=0有效）
        // ==============================================
        if (!code[31]) begin
            // 通用写信号：所有有效指令都赋值
            waddr  = code[26:25];
            we     = 1'b1;

            // ==============================================
            // 步骤4：指令类型分支解析
            // ==============================================
            case (code[30:29])
                // 分支1：ALU运算指令
                OPTYPE_ALU: begin
                    alu_en   = 1'b1;
                    opcode   = code[28:27];
                    raddr1   = code[24:23];
                    raddr2   = code[22:21];
                end

                // 分支2：立即数写入指令
                OPTYPE_IMM: begin
                    imm_en   = 1'b1;
                    imm_data = {7'd0, code[24:0]};
                end

                // 默认分支：无效指令类型（保持默认值）
                default: ;
            endcase
        end
    end
end

endmodule
// ALU模块：严格纯组合逻辑（输出为wire，无reg，无时序逻辑）
module alu(
    input [1:0] opcode,    // 0:add 1:sub 2:mul 3:div
    input [31:0] lhs,      // 第一个操作数（来自寄存器堆）
    input [31:0] rhs,      // 第二个操作数（来自寄存器堆）
    output wire [31:0] ret // 运算结果（纯组合逻辑输出，wire类型）
);

// 用assign实现纯组合逻辑
assign ret = (opcode == 2'b00) ? (lhs + rhs) :
             (opcode == 2'b01) ? (lhs - rhs) :
             (opcode == 2'b10) ? (lhs * rhs) :
             (opcode == 2'b11) ? ((rhs == 32'd0) ? 32'd0 : (lhs / rhs)) :
             32'd0;

// reg [31:0] ret_reg;
// always @(*) begin
//     case(opcode)
//         2'b00: ret_reg = lhs + rhs;
//         2'b01: ret_reg = lhs - rhs;
//         2'b10: ret_reg = lhs * rhs;
//         2'b11: ret_reg = (rhs == 32'd0) ? 32'd0 : (lhs / rhs);
//         default: ret_reg = 32'd0;
//     endcase
// end
// assign ret = ret_reg;

endmodule
// 流水线版顶层模块：补全ID→EX锁存，解决we错位
module top(
    input clk,
    input rst_n,
    output [31:0] ret
);

// ---------------------- 1. 流水线锁存寄存器（补全ID→EX） ----------------------
wire [31:0] code;
// IF→ID：锁存指令
reg [31:0] if2id_code;
// ID→EX：锁存译码器的所有输出
reg id2ex_alu_en;
reg [1:0] id2ex_opcode;
reg [1:0] id2ex_raddr1;
reg [1:0] id2ex_raddr2;
reg [1:0] id2ex_waddr;
reg id2ex_we;          // 锁存后的we
reg id2ex_imm_en;
reg [31:0] id2ex_imm_data;

// ---------------------- 2. 原有信号 ----------------------
wire alu_en;
wire [1:0] opcode;
wire [1:0] raddr1;
wire [1:0] raddr2;
wire [1:0] waddr;
wire we;              // 译码器输出的组合逻辑we
wire imm_en;
wire [31:0] imm_data;
wire [31:0] rdata1;
wire [31:0] rdata2;
wire [31:0] alu_ret;
wire [31:0] pc;

// ---------------------- 3. 流水线节拍推进 ----------------------
// IF→ID：锁存指令
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) if2id_code <= 32'd0;
    else if2id_code <= code;
end

// ID→EX：锁存译码器所有输出
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        id2ex_alu_en <= 1'b0;
        id2ex_opcode <= 2'b00;
        id2ex_raddr1 <= 2'd0;
        id2ex_raddr2 <= 2'd0;
        id2ex_waddr <= 2'd0;
        id2ex_we <= 1'b0;    // 锁存后的we初始化
        id2ex_imm_en <= 1'b0;
        id2ex_imm_data <= 32'd0;
    end else begin
        // 把译码器的组合逻辑输出，锁存为时序信号（和时钟沿对齐）
        id2ex_alu_en <= alu_en;
        id2ex_opcode <= opcode;
        id2ex_raddr1 <= raddr1;
        id2ex_raddr2 <= raddr2;
        id2ex_waddr <= waddr;
        id2ex_we <= we;
        id2ex_imm_en <= imm_en;
        id2ex_imm_data <= imm_data;
    end
end

// ---------------------- 4. 写使能/写数据逻辑 ----------------------
// 最终写使能：用锁存后的id2ex_we（和时钟沿对齐）
wire valid_en = id2ex_we;

// 写数据选择：用锁存后的信号
wire [31:0] reg_wdata = id2ex_imm_en ? id2ex_imm_data : alu_ret;

// ALU/立即数写使能：用锁存后的信号
wire alu_we = id2ex_alu_en & valid_en & ~id2ex_imm_en;
wire imm_we = id2ex_imm_en & valid_en;

// ---------------------- 5. 模块实例化 ----------------------
fetcher u_fetcher(
  .clk(clk),
  .rst_n(rst_n),
  .flush(1'b0),
  .inst(code)
);

decoder u_decoder(
    .clk(clk),
    .rst_n(rst_n),
    .code(if2id_code),  // 输入锁存的指令
    .alu_en(alu_en),
    .opcode(opcode),
    .raddr1(raddr1),
    .raddr2(raddr2),
    .waddr(waddr),
    .we(we),
    .imm_en(imm_en),
    .imm_data(imm_data)
);

reg_file u_reg_file(
    .clk(clk),
    .rst_n(rst_n),
    .we(alu_we | imm_we),
    .waddr(id2ex_waddr), //用锁存后的写地址（和we同步）
    .wdata(reg_wdata),
    .raddr1(id2ex_raddr1), // 用锁存后的读地址
    .raddr2(id2ex_raddr2),
    .rdata1(rdata1),
    .rdata2(rdata2)
);

alu u_alu(
    .opcode(id2ex_opcode),
    .lhs(rdata1),
    .rhs(rdata2),
    .ret(alu_ret)
);

assign ret = alu_ret;

endmodule
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
