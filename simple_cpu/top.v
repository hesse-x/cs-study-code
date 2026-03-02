// 顶层模块：新增立即数写入寄存器逻辑，兼容原有功能
module top(
    input clk,
    input rst_n,
    input [31:0] code
);

// ---------------------- 信号声明 ----------------------
// 译码器输出（新增立即数相关）
wire alu_en;          // ALU运算指令使能
wire [1:0] opcode;    // 运算类型
wire [1:0] raddr1;    // 读寄存器1地址
wire [1:0] raddr2;    // 读寄存器2地址
wire [1:0] waddr;     // 写寄存器地址
wire we;              // 通用写使能
wire imm_en;          // 立即数指令使能（新增）
wire [31:0] imm_data; // 立即数数据（新增）

// 寄存器堆输出
wire [31:0] rdata1;   // 寄存器1读出数据
wire [31:0] rdata2;   // 寄存器2读出数据

// ALU输出（纯组合逻辑）
wire [31:0] alu_ret;  // ALU运算结果

// 间隔执行机制
reg alu_exec_flag;    // ALU/立即数执行标记（共用）

// ---------------------- 间隔执行逻辑 ----------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        alu_exec_flag <= 1'b0; 
    end
    else begin
        alu_exec_flag <= ~alu_exec_flag; 
    end
end

// 最终有效使能：通用使能 + 执行标记（ALU/立即数指令共用）
wire valid_en = we & alu_exec_flag;

// 新增：寄存器写数据选择（立即数指令优先级 > ALU指令）
wire [31:0] reg_wdata = imm_en ? imm_data : alu_ret;
// 新增：ALU写使能（仅ALU指令有效且非立即数指令）
wire alu_we = alu_en & valid_en & ~imm_en;
// 新增：立即数写使能（仅立即数指令有效）
wire imm_we = imm_en & valid_en;

// ---------------------- 模块实例化 ----------------------
// 1. 译码器（已扩展立即数指令）
decoder u_decoder(
    .clk(clk),
    .rst_n(rst_n),
    .code(code),
    .alu_en(alu_en),
    .opcode(opcode),
    .raddr1(raddr1),
    .raddr2(raddr2),
    .waddr(waddr),
    .we(we),
    .imm_en(imm_en),       // 新增立即数使能
    .imm_data(imm_data)    // 新增立即数数据
);

// 2. 寄存器堆（复用原有，仅修改写使能和写数据）
reg_file u_reg_file(
    .clk(clk),
    .rst_n(rst_n),
    .we(alu_we | imm_we),  // ALU写或立即数写
    .waddr(waddr),
    .wdata(reg_wdata),     // 选择立即数或ALU结果写回
    .raddr1(raddr1),
    .raddr2(raddr2),
    .rdata1(rdata1),
    .rdata2(rdata2)
);

// 3. ALU（纯组合逻辑，无改动）
alu u_alu(
    .opcode(opcode),
    .lhs(rdata1),
    .rhs(rdata2),
    .ret(alu_ret)
);

// 输出：ALU结果（仅ALU指令有效）
assign ret = alu_ret;

endmodule
