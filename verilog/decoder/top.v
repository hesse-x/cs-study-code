// 顶层模块（修复信号命名、冗余定义、复位逻辑）
module top(
    input clk,
    input rst_n,
    input [31:0] code,
    output [31:0] ret
);

// 修复点1：删除冗余的alu_lhs/alu_rhs，正确声明decoder输出的lhs/rhs
wire alu_en;          // 重命名alu为alu_en，语义更清晰
wire [1:0] opcode;
wire [31:0] lhs;       // decoder输出是reg，top中用reg接收（或wire，不影响）
wire [31:0] rhs;

// 修复点2：简化alu复位逻辑，命名改为alu_rst_n（低有效，匹配alu的rst_n）
// 逻辑：全局复位rst_n=0 或 ALU未使能(alu_en=0)时，alu复位（rst_n=0）
wire alu_rst_n = rst_n & alu_en;

// 实例化解码器（修复信号连接）
decoder u_decoder(
    .clk(clk),
    .rst_n(rst_n),
    .code(code),
    .alu_en(alu_en),    // 修复：对应decoder的alu_en输出
    .opcode(opcode),
    .lhs(lhs),
    .rhs(rhs)
);

// 实例化ALU（修复复位信号连接、lhs/rhs连接）
alu u_alu(
    .clk(clk),
    .rst_n(alu_rst_n),  // 低有效复位，匹配逻辑
    .opcode(opcode),
    .lhs(lhs),
    .rhs(rhs),
    .ret(ret)
);

endmodule
