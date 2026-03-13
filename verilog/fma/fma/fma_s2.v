module fma_s2 (
    input [1:0] inv,

    input t_sign,
    input [common::EXP_WIDTH-1:0] t_exp,
    input [common::INTERNAL_MANT_WIDTH-1:0] t_mant,

    input c_sign,
    input [common::EXP_WIDTH-1:0] c_exp,
    input [common::INTERNAL_MANT_WIDTH-1:0] c_mant,

    output r_sign,
    output [common::EXP_WIDTH-1:0] r_exp,
    output [common::INTERNAL_MANT_WIDTH-1:0] r_mant
);

localparam MANT_START = common::INTERNAL_MANT_WIDTH-2;
localparam MANT_END = common::INTERNAL_MANT_WIDTH-25;
wire t_sign_inv = t_sign ^ inv[0];
wire c_sign_inv = c_sign ^ inv[1];
wire exp_t_gt_c = t_exp > c_exp;
wire exp_t_eq_c = t_exp == c_exp;
wire mant_t_lt_c = t_mant[MANT_START:MANT_END] <
                       c_mant[MANT_START:MANT_END];
wire t_gt_c = exp_t_gt_c | ~mant_t_lt_c;
wire [common::EXP_WIDTH-1:0] exp_diff = exp_t_gt_c ? (t_exp - c_exp) : (c_exp - t_exp);
wire [common::EXP_WIDTH-1:0] exp_large = exp_t_gt_c ? t_exp : c_exp;
wire [common::INTERNAL_MANT_WIDTH-1:0] mant_large = t_gt_c ? t_mant : c_mant;
wire [common::INTERNAL_MANT_WIDTH-1:0] mant_small = t_gt_c ? c_mant : t_mant;

assign r_sign = t_gt_c ? t_sign_inv : c_sign_inv;
assign r_exp = exp_large;
assign r_mant = (t_sign_inv ^ c_sign_inv) ? mant_large - mant_small : mant_large + mant_small;
endmodule
