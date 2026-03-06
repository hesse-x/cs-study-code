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
