module alu(
    input clk,
    input rst_n,
    // opcode:
    //   add 0
    //   sub 0
    //   mul 0
    //   div 0
    input [1:0] opcode,
    input [31:0] lhs,
    input [31:0] rhs,
    output reg [31:0] ret
);

always @(posedge clk or negedge rst_n) begin
   if (!rst_n) begin
      ret <= 0;
   end
   else if (opcode == 0) begin
      ret <= lhs + rhs;
   end
   else if (opcode == 1) begin
      ret <= lhs - rhs;
   end
   else if (opcode == 2) begin
      ret <= lhs * rhs;
   end
   else if (opcode == 3) begin
      ret <= lhs / rhs;
   end
end

endmodule
