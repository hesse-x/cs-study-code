// ALU模块（修复注释、增加除法除0保护）
module alu(
    input clk,
    input rst_n,
    // opcode注释修正：
    //   0: add 加法
    //   1: sub 减法
    //   2: mul 乘法
    //   3: div 除法（含除0保护）
    input [1:0] opcode,
    input [31:0] lhs,
    input [31:0] rhs,
    output reg [31:0] ret
);

always @(posedge clk or negedge rst_n) begin
   if (!rst_n) begin
      ret <= 32'd0;  // 非阻塞赋值（原本正确，保留）
   end
   else begin
      case(opcode)
         2'b00: ret <= lhs + rhs;                  // 加法
         2'b01: ret <= lhs - rhs;                  // 减法
         2'b10: ret <= lhs * rhs;                  // 乘法
         2'b11: ret <= (rhs == 32'd0) ? 32'd0 : (lhs / rhs); // 修复：除0保护
         default: ret <= 32'd0;                    // 增加默认值，避免X态
      endcase
   end
end

endmodule
