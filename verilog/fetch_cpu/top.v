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
