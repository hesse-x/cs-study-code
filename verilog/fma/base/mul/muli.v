module mul_4bit (
input [3:0] a,
input [3:0] b,
output [3:0] c
);

assign c = a * b;
endmodule

module mul_8bit (
input [7:0] a,
input [7:0] b,
output [7:0] c
);

assign c = a * b;
endmodule

module mul_25bit (
    input [24:0] a,
    input [24:0] b,
    output [24:0] c
);

assign c = a * b;
endmodule

module mul_48bit (
    input [47:0] a,
    input [47:0] b,
    output [47:0] c
);

assign c = a * b;
endmodule

module mulc_4bit (
input [3:0] a,
output [3:0] c
);

assign c = a * 4'b0011;
endmodule

module mulc_8bit (
input [7:0] a,
output [7:0] c
);

assign c = a * 8'b11111100;
endmodule

