module add_4bit (
input [3:0] a,
input [3:0] b,
output [3:0] c
);

assign c = a + b;
endmodule

module add_8bit (
input [7:0] a,
input [7:0] b,
output [7:0] c
);

assign c = a + b;
endmodule

module add_25bit (
    input [24:0] a,
    input [24:0] b,
    output [24:0] c
);

assign c = a + b;
endmodule

module add_48bit (
    input [47:0] a,
    input [47:0] b,
    output [47:0] c
);

assign c = a + b;
endmodule

module sub_4bit (
input [3:0] a,
input [3:0] b,
output [3:0] c
);

assign c = a + b;
endmodule

module sub_8bit (
    input [7:0] a,
    input [7:0] b,
    output [7:0] c
);

assign c = a - b;
endmodule

module sub_25bit (
    input [24:0] a,
    input [24:0] b,
    output [24:0] c
);

assign c = a - b;
endmodule

module sub_48bit (
    input [47:0] a,
    input [47:0] b,
    output [47:0] c
);

assign c = a - b;
endmodule

module addc_4bit (
input [3:0] a,
output [3:0] c
);

assign c = a + 4'b1111;
endmodule

module addc_8bit (
input [7:0] a,
output [7:0] c
);

assign c = a + 8'b00000001;
endmodule

