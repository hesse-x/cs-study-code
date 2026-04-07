module fma(
    input  en,
    input  [1:0] optype, // 00:add, 01:mul, 10:fma
    input  [1:0] inv,
    input  [31:0] a,
    input  [31:0] b,
    input  [31:0] c,
    output [31:0] ret
);

// split inputs
wire a_sign;
wire [7:0] a_exp;
wire [23:0] a_mant;
wire a_is_inf;
wire a_is_nan;
wire a_is_zero;
splitf u_split_a(
    .in(a),
    .exp(a_exp),
    .sign(a_sign),
    .mant(a_mant),
    .is_inf(a_is_inf),
    .is_nan(a_is_nan),
    .is_zero(a_is_zero));

wire b_sign;
wire [7:0] b_exp;
wire [23:0] b_mant;
wire b_is_inf;
wire b_is_nan;
wire b_is_zero;
splitf u_split_b(
    .in(b),
    .exp(b_exp),
    .sign(b_sign),
    .mant(b_mant),
    .is_inf(b_is_inf),
    .is_nan(b_is_nan),
    .is_zero(b_is_zero));

wire c_sign;
wire [7:0] c_exp;
wire [23:0] c_mant;
wire c_is_inf;
wire c_is_nan;
wire c_is_zero;

splitf u_split_c(
    .in(c),
    .exp(c_exp),
    .sign(c_sign),
    .mant(c_mant),
    .is_inf(c_is_inf),
    .is_nan(c_is_nan),
    .is_zero(c_is_zero));


wire [7:0] exp_add = a_exp + b_exp;
wire [7:0] t_exp = exp_add > 127 ? exp_add - 127 : '0;

wire exp_t_gt_c = t_exp > c_exp;
wire [4:0] exp_diff = exp_t_gt_c ? t_exp - c_exp : c_exp - t_exp;

wire [47:0] sum;
wire [47:0] cout;
prod u_prod(
    .a(a_mant),
    .b(b_mant),
    .sum(sum),
    .cout(cout)
);

wire [47:0] shifted_sum = exp_t_gt_c ? sum : sum >> exp_diff;
wire [47:0] shifted_cout = exp_t_gt_c ? cout : cout >> exp_diff;
wire [47:0] padded_c_mant = {1'b0, c_mant, 23'b0};
wire [47:0] shifted_c_mant = exp_t_gt_c ? padded_c_mant >> exp_diff : padded_c_mant;

wire inved_a_sign = a_sign ^ inv[0];
wire inved_c_sign = c_sign ^ inv[1];
wire is_sub = inved_a_sign ^ b_sign ^ inved_c_sign;
wire [47:0] cin = is_sub ? 48'b1 : 48'b0;
wire [47:0] sub_c_mant = is_sub ? ~shifted_c_mant : shifted_c_mant;

wire [47:0] sum1;
wire [47:0] cout1;
add_full u_add1(
  .a   (shifted_sum), .b(shifted_cout), .cin(sub_c_mant),
  .sum (sum1), .cout(cout1)
);

wire [47:0] r_sum;
wire [47:0] r_cout;
add_full u_add2(
  .a   (sum1), .b(cout1), .cin(cin),
  .sum (r_sum), .cout(r_cout)
);

wire [47:0] r_mant;
assign r_mant = r_sum + r_cout;

wire [5:0] first1_pos;
wire all_zero;

find_first1_pad_to_64bit #(.W(48)) u_find(
    .in(r_mant),
    .all_zero(all_zero),
    .out(first1_pos)
);

wire [7:0] r_exp = exp_t_gt_c ? t_exp : c_exp;
wire can_normed = (r_exp + first1_pos > 46) | (r_exp == 8'hff & r_mant[47]);
wire signed [6:0] shift_amt = {1'b0, first1_pos} - 7'd23;
wire signed [6:0] exp_corr = {1'b0, first1_pos} - 7'd46;

wire [47:0] normalized_mant = (shift_amt >= 0) ? (r_mant >> shift_amt) : (r_mant << (-shift_amt));

wire [7:0] exp_corr_padded = {exp_corr[6], exp_corr};
wire [7:0] final_exp = all_zero ? 8'h0 : (r_exp + exp_corr_padded);

wire [6:0] denormed_shift = r_exp > 0 ? r_exp - 1 : r_exp;
wire [47:0] denormed_mant = (r_mant << denormed_shift) >> 23;
wire r_sign = is_sub & r_mant[47];
assign ret = can_normed ? {r_sign, final_exp, normalized_mant[22:0]} : {r_sign, 8'h00, denormed_mant[22:0]};

endmodule
