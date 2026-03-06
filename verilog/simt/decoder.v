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
    input [common::CODE_WIDTH-1:0] code,
    output reg alu_en [0:common::THD_NUM-1],       // ALU运算指令使能
    output reg [common::OPTYPE_WIDTH-1:0] opcode [0:common::THD_NUM-1], // 运算类型（仅ALU指令有效）
    // 寄存器读地址（仅ALU指令有效）
    output reg [common::REG_ADDR_WIDTH-1:0] raddr1 [0:common::THD_NUM-1],
    output reg [common::REG_ADDR_WIDTH-1:0] raddr2 [0:common::THD_NUM-1],
    // 写寄存器地址（ALU/立即数指令共用）
    output reg [common::REG_ADDR_WIDTH-1:0] waddr [0:common::THD_NUM-1],
    output reg we [0:common::THD_NUM-1],
    output reg imm_en [0:common::THD_NUM-1],         // 立即数写入指令使能
    output reg [common::DATA_WIDTH-1:0] imm_data [0:common::THD_NUM-1] // 立即数数据
);

// 本地参数：仅内部使用，不修改外部接口
localparam OPTYPE_ALU    = 2'b00;  // ALU指令（code[30:29]）
localparam OPTYPE_IMM    = 2'b01;  // 立即数指令（code[30:29]）

always @(*) begin
    integer i;
    for(i = 0; i < common::REG_NUM; i = i + 1) begin
        alu_en[i]    = 1'b0;
        opcode[i]    = 2'b00;
        raddr1[i]    = 2'd0;
        raddr2[i]    = 2'd0;
        waddr[i]     = 2'd0;
        we[i]        = 1'b0;
        imm_en[i]    = 1'b0;
        imm_data[i]  = 32'd0;

        if (rst_n) begin
            if (!code[31]) begin
                waddr[i]  = code[26:25];
                we[i]     = 1'b1;

                case (code[30:29])
                    OPTYPE_ALU: begin
                        alu_en[i]   = 1'b1;
                        opcode[i]   = code[28:27];
                        raddr1[i]   = code[24:23];
                        raddr2[i]   = code[22:21];
                    end

                    OPTYPE_IMM: begin
                        imm_en[i]   = 1'b1;
                        imm_data[i] = {7'd0, code[24:0]};
                    end

                    default: ;
                endcase
            end
        end
    end
end

endmodule
