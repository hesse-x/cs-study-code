// 译码器模块：新增立即数写入指令解析
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
    // 新增：立即数指令相关信号
    output reg imm_en,       // 立即数写入指令使能
    output reg [31:0] imm_data // 立即数数据
);

// 指令格式约定（扩展后）：
// 1. ALU运算指令（原有）：
//    code[31]   ：指令有效位（1=无效，0=有效）
//    code[30:29]：optype（00=alu/01=io）
//    code[28:27]：opcode（00=add/01=sub/10=mul/11=div）
//    code[26:25]：写寄存器地址waddr（r0-r3）
//    code[24:23]：读寄存器地址raddr1（r0-r3）
//    code[22:21]：读寄存器地址raddr2（r0-r3）
//    code[20:0] ：保留
// 2. 立即数写入指令：
//    code[31]   ：指令有效位（1=无效，0=有效）
//    code[30:29]：optype（00=alu/01=io）
//    code[28:27]：opcode（保留）
//    code[26:25]：写寄存器地址waddr（r0-r3）
//    code[24:0] ：32位立即数的低25位

always @(posedge clk or negedge rst_n) begin
   if (!rst_n) begin
      alu_en <= 1'b0;    
      opcode <= 2'b00;   
      raddr1 <= 2'd0;
      raddr2 <= 2'd0;
      waddr  <= 2'd0;
      we     <= 1'b0;
      imm_en <= 1'b0;    // 复位后立即数指令禁用
      imm_data <= 32'd0; // 复位后立即数清零
   end
   else begin
      // 先默认清零所有信号，避免X态
      alu_en <= 1'b0;
      opcode <= 2'b00;
      raddr1 <= 2'd0;
      raddr2 <= 2'd0;
      waddr  <= 2'd0;
      we     <= 1'b0;
      imm_en <= 1'b0;
      imm_data <= 32'd0;

      if (!code[31]) begin // 指令有效
         waddr <= code[26:25]; // 写地址通用
         we <= 1'b1;          // 通用写使能有效

         // 识别指令类型：optype:00=alu/01=io
         if (code[30:29] == 2'b01) begin 
            imm_en <= 1'b1; // 立即数指令使能
            // 拼接32位立即数：code[26:0]（低27位） + 高5位补0（可根据需求调整）
            imm_data <= {7'd0, code[24:0]}; 
         end else begin
            alu_en <= 1'b1; // ALU运算指令使能
            opcode <= code[28:27]; // 运算类型
            raddr1 <= code[24:23]; // 读地址1
            raddr2 <= code[22:21]; // 读地址1
         end
      end
   end
end

endmodule
