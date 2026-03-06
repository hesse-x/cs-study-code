module simt(
    input clk,
    input rst_n,
    input [common::CODE_WIDTH-1:0] code
);

wire alu_en [0:common::THD_NUM-1];
wire [common::OPTYPE_WIDTH-1:0] opcode [0:common::THD_NUM-1];
wire [common::REG_ADDR_WIDTH-1:0] raddr1 [0:common::THD_NUM-1];
wire [common::REG_ADDR_WIDTH-1:0] raddr2 [0:common::THD_NUM-1];
wire [common::REG_ADDR_WIDTH-1:0] waddr [0:common::THD_NUM-1];
wire we [0:common::THD_NUM-1];              // 译码器输出的组合逻辑we
wire imm_en [0:common::THD_NUM-1];
wire [common::DATA_WIDTH-1:0] imm_data [0:common::THD_NUM-1];
wire [common::DATA_WIDTH-1:0] rdata1 [0:common::THD_NUM-1];
wire [common::DATA_WIDTH-1:0] rdata2 [0:common::THD_NUM-1];
wire [common::DATA_WIDTH-1:0] alu_ret [0:common::THD_NUM-1];

// IF→ID：锁存指令
reg [31:0] if2id_code;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) if2id_code <= 32'd0;
    else if2id_code <= code;
end

// ID→EX：锁存译码器所有输出
reg id2ex_alu_en [0:common::THD_NUM-1];
reg [common::OPTYPE_WIDTH-1:0] id2ex_opcode [0:common::THD_NUM-1];
reg [common::REG_ADDR_WIDTH-1:0] id2ex_raddr1 [0:common::THD_NUM-1];
reg [common::REG_ADDR_WIDTH-1:0] id2ex_raddr2 [0:common::THD_NUM-1];
reg [common::REG_ADDR_WIDTH-1:0] id2ex_waddr [0:common::THD_NUM-1];
reg id2ex_we [0:common::THD_NUM-1];          // 锁存后的we
reg id2ex_imm_en [0:common::THD_NUM-1];
reg [common::DATA_WIDTH-1:0] id2ex_imm_data [0:common::THD_NUM-1];
always @(posedge clk or negedge rst_n) begin
    integer i;
    for(i = 0; i < common::THD_NUM; i = i + 1) begin
        if (!rst_n) begin
            id2ex_alu_en[i] <= 1'b0;
            id2ex_opcode[i] <= 2'b00;
            id2ex_raddr1[i] <= 2'd0;
            id2ex_raddr2[i] <= 2'd0;
            id2ex_waddr[i] <= 2'd0;
            id2ex_we[i] <= 1'b0;
            id2ex_imm_en[i] <= 1'b0;
            id2ex_imm_data[i] <= 32'd0;
        end else begin
            id2ex_alu_en[i] <= alu_en[i];
            id2ex_opcode[i] <= opcode[i];
            id2ex_raddr1[i] <= raddr1[i] + i * common::MAX_REG_NUM_PER_THD;
            id2ex_raddr2[i] <= raddr2[i] + i * common::MAX_REG_NUM_PER_THD;
            id2ex_waddr[i] <= waddr[i] + i * common::MAX_REG_NUM_PER_THD;
            id2ex_we[i] <= we[i];
            id2ex_imm_en[i] <= imm_en[i];
            id2ex_imm_data[i] <= imm_data[i];
        end
    end
end

reg valid_en[0:common::THD_NUM-1];
reg [common::DATA_WIDTH-1:0] reg_wdata[0:common::THD_NUM-1];
reg alu_we[0:common::THD_NUM-1];
reg imm_we[0:common::THD_NUM-1];
reg reg_we[0:common::THD_NUM-1];

always @(*) begin
    integer i;
    for(i = 0; i < common::THD_NUM; i = i + 1) begin
      valid_en[i] = id2ex_we[i];
      reg_wdata[i] = id2ex_imm_en[i] ? id2ex_imm_data[i] : alu_ret[i];
      alu_we[i] = id2ex_alu_en[i] & valid_en[i] & ~id2ex_imm_en[i];
      imm_we[i] = id2ex_imm_en[i] & valid_en[i];
      reg_we[i] = alu_we[i] | imm_we[i];
    end
end

decoder u_decoder(
    .clk(clk),
    .rst_n(rst_n),
    .code(if2id_code),
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
    .we(reg_we),
    .waddr(id2ex_waddr),
    .wdata(reg_wdata),
    .raddr1(id2ex_raddr1),
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
endmodule
