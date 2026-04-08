module fma(
    input  [1:0] inv,
    // 000     RNE最近舍入，偶数优先默认模式，中间值选偶数
    // 001     RTZ向零舍入截断法，直接舍弃小数
    // 010     RDN向负无穷舍入向下取整 (Floor)
    // 011     RUP向正无穷舍入向上取整 (Ceiling)
    // 100     RMM最近舍入，远零优先四舍五入（中间值绝对值变大）
    // 101-111 Reserve 无效通常用于表示“动态模式”或留作扩展
    input  [2:0] rm,
    input  [31:0] a,
    input  [31:0] b,
    input  [31:0] c,
    output [31:0] ret
);

// split inputs
wire a_sign;
wire [7:0] a_exp;
wire [23:0] a_mant;
splitf u_split_a(
    .in(a),
    .exp(a_exp),
    .sign(a_sign),
    .mant(a_mant),
    .is_inf(),
    .is_nan(),
    .is_zero()
);

wire b_sign;
wire [7:0] b_exp;
wire [23:0] b_mant;
splitf u_split_b(
    .in(b),
    .exp(b_exp),
    .sign(b_sign),
    .mant(b_mant),
    .is_inf(),
    .is_nan(),
    .is_zero()
);

wire c_sign;
wire [7:0] c_exp;
wire [23:0] c_mant;

splitf u_split_c(
    .in(c),
    .exp(c_exp),
    .sign(c_sign),
    .mant(c_mant),
    .is_inf(),
    .is_nan(),
    .is_zero()
);

wire [7:0] exp_add = a_exp + b_exp;
wire [7:0] t_exp = exp_add - 127;

wire exp_t_gt_c = t_exp > c_exp;
wire [7:0] exp_diff_raw = exp_t_gt_c ? (t_exp - c_exp) : (c_exp - t_exp);
wire [4:0] exp_diff = exp_diff_raw[4:0];

wire [47:0] sum;
wire [47:0] cout;
prod u_prod(
    .a(a_mant),
    .b(b_mant),
    .sum(sum),
    .cout(cout)
);

wire [48:0] padded_c_mant = {2'b0, c_mant, 23'b0};

wire [47:0] shifted_sum = exp_t_gt_c ? sum : sum >> exp_diff;
wire [47:0] shifted_cout = exp_t_gt_c ? cout : cout >> exp_diff;
wire [48:0] shifted_c_mant = exp_t_gt_c ? padded_c_mant >> exp_diff : padded_c_mant;
wire [7:0] r_exp = exp_t_gt_c ? t_exp : c_exp;

wire is_sub = (a_sign ^ b_sign ^ inv[0]) ^ (c_sign ^ inv[1]);
wire [48:0] sub_c_mant = is_sub ? ~shifted_c_mant : shifted_c_mant;
wire [48:0] padded_sum = {1'b0, shifted_sum};
wire [48:0] padded_cout = {1'b0, shifted_cout};

wire [48:0] sum1;
wire [48:0] cout1;
add_compressor #(.WIDTH(49)) u_add1(
  .a   (padded_sum), .b(padded_cout), .cin(sub_c_mant),
  .sum (sum1), .cout(cout1)
);

wire [48:0] r0;
wire c0;
assign {c0, r0} = sum1 + cout1;

wire [48:0] cin = 49'b1;
wire [48:0] r_sum;
wire [48:0] r_cout;
add_compressor #(.WIDTH(49)) u_add2(
  .a   (sum1), .b(cout1), .cin(cin),
  .sum (r_sum), .cout(r_cout)
);

// C：A>B 时 |A−B|
// C = A + ∼B + 1
// D：A>B 时 |A−B| + 1
// D = A + ∼B + 2
// E：A<B 时 |A−B|
// E= ∼(A + ∼B)
// F：A<B 时 |A−B| + 1
// F= ∼(A + ∼B - 1)

// r0 = sum1 + cout1 = A + ~B
// C = r0 + 1 = sum1 + cout1 + 1;
// D = r0 + 2 = sum1 + cout1 + 2;
// E = ~r0 = ~(sum1 + cout1);
// F = ~(r0 - 1) = ~(sum1 + cout1 - 1);
wire [48:0] add_result = r0;
wire [48:0] sub_result = c0 ? r_sum + r_cout : ~r0;
wire [48:0] r_mant = is_sub ? sub_result : add_result;

wire [5:0] first1_pos;
wire all_zero;

find_first1_64bit u_find(
    .in({15'b0, r_mant}),
    .all_zero(all_zero),
    .out(first1_pos)
);

wire can_normed = (r_exp + {2'b0, first1_pos} > 46) | (r_exp == 8'hff & r_mant[47]);
wire signed [6:0] shift_amt = {1'b0, first1_pos} - 7'd23;
wire signed [6:0] exp_corr = {1'b0, first1_pos} - 7'd46;

wire [48:0] normalized_mant = (shift_amt >= 0) ? (r_mant >> shift_amt) : (r_mant << (-shift_amt));

wire [7:0] exp_corr_padded = {exp_corr[6], exp_corr};
wire [7:0] final_exp = all_zero ? 8'h0 : (r_exp + exp_corr_padded);

wire [7:0] denormed_shift_8bit = r_exp > 0 ? r_exp - 1 : r_exp;
wire [6:0] denormed_shift = denormed_shift_8bit[6:0];
wire [48:0] denormed_mant = (r_mant << denormed_shift) >> 23;

wire r_sign = (a_sign ^ b_sign ^ inv[0]) ^ (is_sub & ~c0);
assign ret = can_normed ? {r_sign, final_exp, normalized_mant[22:0]} : {r_sign, 8'h00, denormed_mant[22:0]};

endmodule
