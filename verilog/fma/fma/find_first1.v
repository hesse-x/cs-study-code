module find_first1_8bit(
    input [7:0] in,
    output all_zero,
    output [2:0] out
);

wire or_74 = |in[7:4];
wire or_76 = |in[7:6];
wire or_32 = |in[3:2];

assign out[2] = or_74;
assign out[1] = or_74? or_76 : or_32;
assign out[0] = or_74? 
                  (or_76 ? in[7] : in[5]) :
                  (or_32 ? in[3] : in[1]);
assign all_zero = ~|in;
endmodule

module find_first1_16bit(
    input [15:0] in,
    output all_zero,
    output [3:0] out
);

wire [7:0] in_15_8;
wire [7:0] in_7_0;
wire h_all_zero;
wire l_all_zero;
wire [2:0] h_out;
wire [2:0] l_out;

assign in_15_8 = in[15:8];
assign in_7_0 = in[7:0];

assign out[3] = ~h_all_zero;
assign out[2:0] = ~h_all_zero ? h_out : l_out;
assign all_zero = h_all_zero & l_all_zero;

find_first1_8bit u_h_8bit(
    .in(in_15_8),
    .all_zero(h_all_zero),
    .out(h_out)
);
find_first1_8bit u_l_8bit(
    .in(in_7_0),
    .all_zero(l_all_zero),
    .out(l_out)
);
endmodule

module find_first1_32bit(
    input [31:0] in,
    output all_zero,
    output [4:0] out
);

wire [15:0] in_31_16;
wire [15:0] in_15_0;
wire h_all_zero;
wire l_all_zero;
wire [3:0] h_out;
wire [3:0] l_out;

assign in_31_16 = in[31:16];
assign in_15_0 = in[15:0];
assign out[4] = ~h_all_zero;
assign out[3:0] = ~h_all_zero ? h_out : l_out;
assign all_zero = h_all_zero & l_all_zero;
find_first1_16bit u_h_16bit(
    .in(in_31_16),
    .all_zero(h_all_zero),
    .out(h_out)
);

find_first1_16bit u_l_16bit(
    .in(in_15_0),
    .all_zero(l_all_zero),
    .out(l_out)
);
endmodule

module find_first1_64bit(
    input [63:0] in,
    output all_zero,
    output [5:0] out
);

wire [31:0] in_63_32;
wire [31:0] in_31_0;
wire h_all_zero;
wire l_all_zero;
wire [4:0] h_out;
wire [4:0] l_out;

assign in_63_32 = in[63:32];
assign in_31_0 = in[31:0];
assign out[5] = ~h_all_zero;
assign out[4:0] = ~h_all_zero ? h_out : l_out;
assign all_zero = h_all_zero & l_all_zero;
find_first1_32bit u_h_32bit(
    .in(in_63_32),
    .all_zero(h_all_zero),
    .out(h_out)
);

find_first1_32bit u_l_32bit(
    .in(in_31_0),
    .all_zero(l_all_zero),
    .out(l_out)
);
endmodule

module find_first1_pad_to_32bit # (
    parameter W = 25
) (
    input  wire [W-1:0]  in,
    output wire          all_zero,
    output wire [4:0]    out
);

wire [31:0] in_32bit;
assign in_32bit = {{32-W{1'b0}}, in};

find_first1_32bit u_32bit(
    .in        (in_32bit),
    .all_zero  (all_zero),
    .out       (out)
);
endmodule

module find_first1_pad_to_64bit # (
    parameter W = 48
) (
    input  wire [W-1:0]  in,
    output wire          all_zero,
    output wire [5:0]    out
);

wire [63:0] in_64bit;
assign in_64bit = {{64-W{1'b0}}, in};

find_first1_64bit u_64bit(
    .in        (in_64bit),
    .all_zero  (all_zero),
    .out       (out)
);
endmodule
