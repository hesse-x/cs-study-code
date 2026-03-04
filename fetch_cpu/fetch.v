module mem(
    input clk,                  // 时钟（仅写操作同步）
    input [31:0] addr,
    output wire [31:0] data
);

reg [31:0] mem [0:8];
assign data = mem[addr];

endmodule

// 取指单元：PC发生器 + 指令存储器（IMEM）
module fetcher(
    input clk,
    input rst_n,
    input flush,          // 流水线冲刷信号（高有效）
    output [31:0] inst    // 取出的指令（送IF级锁存）
);

reg [31:0] pc;
mem u_mem(
    .clk(clk),
    .addr(pc),
    .data(inst)
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pc <= 0;
    end else begin
      if (inst[31] != 1) begin
          pc <= pc + 1;
      end
    end
end


endmodule
