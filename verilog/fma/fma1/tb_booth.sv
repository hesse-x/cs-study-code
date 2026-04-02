`timescale 1ns/1ps

module tb_booth;
reg [23:0] a;
reg [23:0] b;
wire [71:0] ret [12:0];

booth_encode u_booth (
    .a(a),
    .b(b),
    .ret(ret)
);

initial begin
    $dumpfile("booth.vcd");
    $dumpvars(0, tb_booth);
    
    // 测试用例：A=3, B=4  （简单正数）
    a = 24'd13283;
    b = 24'd2054353;
    #10;
    
    $display("=== 测试 3 × 4 ===");
    $display("生成 12 组编码：0~11");
    $display("a = %b ", a);
    $display("b = %b ", b);
    $display("row0 = %b ", ret[0]);
    $display("row1 = %b ", ret[1]);
    $display("row2 = %b ", ret[2]);
    $display("row3 = %b ", ret[3]);
    $display("row4 = %b ", ret[4]);
    $display("row5 = %b ", ret[5]);
    $display("row6 = %b ", ret[6]);
    $display("row7 = %b ", ret[7]);
    $display("row8 = %b ", ret[8]);
    $display("row9 = %b ", ret[9]);
    $display("row10 = %b ", ret[10]);
    $display("row11 = %b ", ret[11]);
    $display("cout = %b ", ret[12]);
    
    #100;
    $finish;
end

endmodule
