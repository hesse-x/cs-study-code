// ALU模块：严格纯组合逻辑（输出为wire，无reg，无时序逻辑）
module alu(
    input [common::OPTYPE_WIDTH-1:0] opcode [0:common::THD_NUM-1],    // 0:add 1:sub 2:mul 3:div
    input [common::DATA_WIDTH-1:0] lhs [0:common::THD_NUM-1],      // 第一个操作数（来自寄存器堆）
    input [common::DATA_WIDTH-1:0] rhs [0:common::THD_NUM-1],      // 第二个操作数（来自寄存器堆）
    output reg [common::DATA_WIDTH-1:0] ret [0:common::THD_NUM-1] // 运算结果（纯组合逻辑输出，wire类型）
);

always @(*) begin
    integer i;
    for(i = 0; i < common::REG_NUM; i = i + 1) begin
        case(opcode[i])
            2'b00: ret[i] = lhs[i] + rhs[i];
            2'b01: ret[i] = lhs[i] - rhs[i];
            2'b10: ret[i] = lhs[i] * rhs[i];
            2'b11: ret[i] = (rhs[i] == 32'd0) ? 32'd0 : (lhs[i] / rhs[i]);
            default: ret[i] = 32'd0;
        endcase
    end
end

endmodule
