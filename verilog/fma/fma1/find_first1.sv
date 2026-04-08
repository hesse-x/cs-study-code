module find_first1_8bit(
    input [7:0] in,
    output all_zero,
    output [2:0] out
);

wire or_74 = |in[7:4];
wire or_76 = |in[7:6];
wire or_32 = |in[3:2];
wire use_high = or_74;

assign out[2] = use_high;
assign out[1] = use_high ? or_76 : or_32;
assign out[0] = use_high ?
                  (or_76 ? in[7] : in[5]) :
                  (or_32 ? in[3] : in[1]);
assign all_zero = ~|in;
endmodule

module find_first1_16bit(
    input [15:0] in,
    output all_zero,
    output [3:0] out
);

wire h_all_zero;
wire l_all_zero;
wire [2:0] h_out;
wire [2:0] l_out;
wire use_high = ~h_all_zero;

assign out[3] = use_high;
assign out[2:0] = use_high ? h_out : l_out;
assign all_zero = h_all_zero & l_all_zero;

find_first1_8bit u_h_8bit(
    .in(in[15:8]),
    .all_zero(h_all_zero),
    .out(h_out)
);
find_first1_8bit u_l_8bit(
    .in(in[7:0]),
    .all_zero(l_all_zero),
    .out(l_out)
);
endmodule

module find_first1_32bit(
    input [31:0] in,
    output all_zero,
    output [4:0] out
);

wire h_all_zero;
wire l_all_zero;
wire [3:0] h_out;
wire [3:0] l_out;
wire use_high = ~h_all_zero;

assign out[4] = use_high;
assign out[3:0] = use_high ? h_out : l_out;
assign all_zero = h_all_zero & l_all_zero;

find_first1_16bit u_h_16bit(
    .in(in[31:16]),
    .all_zero(h_all_zero),
    .out(h_out)
);

find_first1_16bit u_l_16bit(
    .in(in[15:0]),
    .all_zero(l_all_zero),
    .out(l_out)
);
endmodule

module find_first1_64bit(
    input [63:0] in,
    output all_zero,
    output [5:0] out
);

wire h_all_zero;
wire l_all_zero;
wire [4:0] h_out;
wire [4:0] l_out;
wire use_high = ~h_all_zero;

assign out[5] = use_high;
assign out[4:0] = use_high ? h_out : l_out;
assign all_zero = h_all_zero & l_all_zero;

find_first1_32bit u_h_32bit(
    .in(in[63:32]),
    .all_zero(h_all_zero),
    .out(h_out)
);

find_first1_32bit u_l_32bit(
    .in(in[31:0]),
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

wire [31:0] in_32bit = {{32-W{1'b0}}, in};

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

wire [63:0] in_64bit = {{64-W{1'b0}}, in};

find_first1_64bit u_64bit(
    .in        (in_64bit),
    .all_zero  (all_zero),
    .out       (out)
);
endmodule