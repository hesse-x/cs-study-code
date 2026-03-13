module shift_4bit (
input [3:0] a,
input [2:0] b,
output [3:0] c
);

assign c = a << b;
endmodule

module shift_8bit (
input [7:0] a,
input [3:0] b,
output [7:0] c
);

assign c = a << b;
endmodule

module shift_25bit (
    input [24:0] a,
    input [4:0] b,
    output [24:0] c
);

assign c = a << b;
endmodule

module shift_48bit (
    input [47:0] a,
    input [5:0] b,
    output [47:0] c
);

assign c = a << b;
endmodule

module shiftc_4bit (
input [3:0] a,
output [3:0] c
);

assign c = a << 4'b0011;
endmodule

module shiftc_8bit (
input [7:0] a,
output [7:0] c
);

assign c = a << 8'b11111100;
endmodule

