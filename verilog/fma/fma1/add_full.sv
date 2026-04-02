module add_full(
    input [47:0] a,
    input [47:0] b,
    input [47:0] cin,
    output [47:0] sum,
    output [47:0] cout
);
assign sum  = a ^ b ^ cin;
assign cout = ((a & b) | (a & cin) | (b & cin)) << 1;
endmodule

module csa(
    input [47:0] pp_0,
    input [47:0] pp_1,
    input [47:0] pp_2,
    input [47:0] pp_3,
    input [47:0] pp_4,
    input [47:0] pp_5,
    input [47:0] pp_6,
    input [47:0] pp_7,
    input [47:0] pp_8,
    input [47:0] pp_9,
    input [47:0] pp_10,
    input [47:0] pp_11,
    input [47:0] pp_12,
    output [47:0] sum,
    output [47:0] cout
);

// round1
wire [47:0] r0 [8:0];
add_full u_add_0(
  .a(pp_0), .b(pp_1), .cin(pp_2),
  .sum(r0[0]), .cout(r0[1])
);
add_full u_add_1(
  .a(pp_3), .b(pp_4), .cin(pp_5),
  .sum(r0[2]), .cout(r0[3])
);
add_full u_add_2(
  .a(pp_6), .b(pp_7), .cin(pp_8),
  .sum(r0[4]), .cout(r0[5])
);
add_full u_add_3(
  .a(pp_9), .b(pp_10), .cin(pp_11),
  .sum(r0[6]), .cout(r0[7])
);
assign r0[8] = pp_12;

// round2
wire [47:0] r1 [5:0];
add_full u_add_r2_0(
  .a   (r0[0]), .b(r0[2]), .cin(r0[4]),
  .sum (r1[0]), .cout(r1[1])
);
add_full u_add_r2_1(
  .a   (r0[1]), .b(r0[3]), .cin(r0[5]),
  .sum (r1[2]), .cout(r1[3])
);
add_full u_add_r2_2(
  .a   (r0[6]), .b(r0[7]), .cin(r0[8]),
  .sum (r1[4]), .cout(r1[5])
);

// round3
wire [47:0] r2 [3:0];
add_full u_add_r3_0(
  .a   (r1[0]), .b(r1[2]), .cin(r1[4]),
  .sum (r2[0]), .cout(r2[1])
);
add_full u_add_r3_1(
  .a   (r1[1]), .b(r1[3]), .cin(r1[5]),
  .sum (r2[2]), .cout(r2[3])
);

// round4
wire [47:0] r3 [2:0];
add_full u_add_r4(
  .a   (r2[0]), .b(r2[1]), .cin(r2[2]),
  .sum (r3[0]), .cout(r3[1])
);
assign r3[2] = r2[3];

// round5
add_full u_add_r5(
  .a   (r3[0]), .b(r3[1]), .cin(r3[2]),
  .sum (sum), .cout(cout)
);

endmodule
