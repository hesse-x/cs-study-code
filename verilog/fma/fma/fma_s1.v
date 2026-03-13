// stage1: split inputs and latch a/b/c exp/mant
module fma_s1 (
    input  [common::WIDTH-1:0] a,
    input  [common::WIDTH-1:0] b,
    input  [common::WIDTH-1:0] c,

    output c_sign,
    output [common::EXP_WIDTH-1:0] c_exp,
    output [common::INTERNAL_MANT_WIDTH-1:0] c_mant,

    output t_sign,
    output [common::EXP_WIDTH-1:0] t_exp,
    output [common::INTERNAL_MANT_WIDTH-1:0] t_mant
);

wire a_sign;
wire [common::EXP_WIDTH-1:0] a_exp;
wire [common::MANT_WIDTH-1:0] a_mant;
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
wire [common::EXP_WIDTH-1:0] b_exp;
wire [common::MANT_WIDTH-1:0] b_mant;
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

wire c_is_inf;
wire c_is_nan;
wire c_is_zero;
wire [common::MANT_WIDTH-1:0] c_mant_lbw;
localparam PAD_WIDTH = common::INTERNAL_MANT_WIDTH - common::MANT_WIDTH - 1;
assign c_mant = {1'b0, c_mant_lbw, {PAD_WIDTH{1'b0}}};
splitf u_split_c(
    .in(c),
    .exp(c_exp),
    .sign(c_sign),
    .mant(c_mant_lbw),
    .is_inf(c_is_inf),
    .is_nan(c_is_nan),
    .is_zero(c_is_zero));

fma_mul u_mul(
    .a_sign(a_sign),
    .a_exp(a_exp),
    .a_mant(a_mant),

    .b_sign(b_sign),
    .b_exp(b_exp),
    .b_mant(b_mant),

    .t_sign(t_sign),
    .t_exp(t_exp),
    .t_mant(t_mant)
);

endmodule
