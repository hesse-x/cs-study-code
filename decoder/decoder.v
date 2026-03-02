// 译码器模块（修复阻塞赋值、信号命名、复位逻辑）
module decoder(
    input clk,
    input rst_n,
    input [31:0] code,
    output reg alu_en,       // 重命名alu为alu_en，语义更清晰（ALU使能）
    output reg [1:0] opcode,
    output reg [31:0] lhs,
    output reg [31:0] rhs
);

// 修复点3：时序逻辑全部改为非阻塞赋值（<=）
always @(posedge clk or negedge rst_n) begin
   if (!rst_n) begin
      alu_en <= 1'b0;    // 复位时禁用ALU
      opcode <= 2'b00;   // 复位为加法
      lhs <= 32'd0;
      rhs <= 32'd0;
   end
   else begin
     alu_en <= !code[31];       // 非阻塞赋值
     opcode <= code[30:29];     // 非阻塞赋值
     lhs <= code[27:14];        // 非阻塞赋值
     rhs <= code[13:0];         // 非阻塞赋值
   end
end

endmodule
