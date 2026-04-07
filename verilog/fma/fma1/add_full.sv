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

module part_prod # (
  parameter shift = 0
) (
  input [23:0] a,
  input b,
  output [47:0] ret
);
wire [47:0] padded_a;
assign padded_a = {'0, a};
wire [47:0] padded_b;
assign padded_b = {24'b0, {24{b}}};
wire [47:0] prod;
assign prod = padded_a & padded_b;
assign ret = prod << shift;

endmodule

module prod(
    input [23:0] a,
    input [23:0] b,
    output [47:0] sum,
    output [47:0] cout
);

wire [47:0] r0 [15:0];
wire [47:0] add_a [7:0];
wire [47:0] add_b [7:0];
wire [47:0] add_c [7:0];
generate
    genvar i;
    for (i=0; i<8; i=i+1) begin : encode_loop
      part_prod#(.shift(3*i)) u_prod_a(
          .a(a),
          .b(b[3*i]),
          .ret(add_a[i])
      );
      part_prod#(.shift(3*i+1)) u_prod_b(
          .a(a),
          .b(b[3*i+1]),
          .ret(add_b[i])
      );
      part_prod#(.shift(3*i+2)) u_prod_c(
          .a(a),
          .b(b[3*i+2]),
          .ret(add_c[i])
      );
      add_full u_add_r0(
          .a(add_a[i]),
          .b(add_b[i]),
          .cin(add_c[i]),
          .sum (r0[2*i]),
          .cout(r0[2*i+1])
      );
    end
endgenerate

wire [47:0] r1 [10:0];
generate
    for (i=0; i<5; i=i+1) begin : encode_loop1
      add_full u_add_r1(
          .a   (r0[i*3]),
          .b   (r0[i*3+1]),
          .cin (r0[i*3+2]),
          .sum (r1[2*i]),
          .cout(r1[2*i+1])
      );
    end
endgenerate
assign r1[10] = r0[15];

wire [47:0] r2 [7:0];
generate
    for (i=0; i<3; i=i+1) begin : encode_loop2
      add_full u_add_r2(
          .a   (r1[i*3]),
          .b   (r1[i*3+1]),
          .cin (r1[i*3+2]),
          .sum (r2[2*i]),
          .cout(r2[2*i+1])
      );
    end
endgenerate
assign r2[6] = r1[9];
assign r2[7] = r1[10];

wire [47:0] r3 [5:0];
generate
    for (i=0; i<2; i=i+1) begin : encode_loop3
      add_full u_add_r3(
          .a   (r2[i*3]),
          .b   (r2[i*3+1]),
          .cin (r2[i*3+2]),
          .sum (r3[2*i]),
          .cout(r3[2*i+1])
      );
    end
endgenerate
assign r3[4] = r2[6];
assign r3[5] = r2[7];

wire [47:0] r4 [3:0];
generate
    for (i=0; i<2; i=i+1) begin : encode_loop4
      add_full u_add_r4(
          .a   (r3[i*3]),
          .b   (r3[i*3+1]),
          .cin (r3[i*3+2]),
          .sum (r4[2*i]),
          .cout(r4[2*i+1])
      );
    end
endgenerate

wire [47:0] r5 [2:0];
add_full u_add_r5(
    .a   (r4[0]),
    .b   (r4[1]),
    .cin (r4[2]),
    .sum (r5[0]),
    .cout(r5[1])
);
assign r5[2] = r4[3];

add_full u_add_r6(
    .a   (r5[0]),
    .b   (r5[1]),
    .cin (r5[2]),
    .sum (sum),
    .cout(cout)
);

endmodule
