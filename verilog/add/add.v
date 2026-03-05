module add(
    input clk,
    input rst_n,
    input [31:0] lhs,
    input [31:0] rhs,
    output reg [31:0] ret
);

always @(posedge clk or negedge rst_n) begin
   if (!rst_n) begin
      ret <= 0;
   end
   else begin
      ret <= lhs + rhs;
   end
end

endmodule
