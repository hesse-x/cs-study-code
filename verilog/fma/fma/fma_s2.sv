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

    localparam MANT_WIDTH = common::INTERNAL_MANT_WIDTH;

    wire t_sign_inv = t_sign ^ inv[0];
    wire c_sign_inv = c_sign ^ inv[1];

    wire exp_t_gt_c = t_exp > c_exp;
    wire [common::EXP_WIDTH-1:0] exp_diff = exp_t_gt_c ? (t_exp - c_exp) : (c_exp - t_exp);
    
    wire [MANT_WIDTH-1:0] mant_large = exp_t_gt_c ? t_mant : c_mant;
    wire [MANT_WIDTH-1:0] mant_small = exp_t_gt_c ? c_mant : t_mant;
    wire [MANT_WIDTH-1:0] mant_small_shifted = (exp_diff >= MANT_WIDTH) ? '0 : (mant_small >> exp_diff);

    wire mant_t_gt_c = t_mant > c_mant;
    wire res_t_gt_c  = exp_t_gt_c || (t_exp == c_exp && mant_t_gt_c);

    assign r_sign = res_t_gt_c ? t_sign_inv : c_sign_inv;
    assign r_exp  = exp_t_gt_c ? t_exp : c_exp;

    assign r_mant = (t_sign_inv ^ c_sign_inv) ? 
                    (res_t_gt_c ? (t_mant - (c_mant >> exp_diff)) : (c_mant - (t_mant >> exp_diff))) : 
                    (mant_large + mant_small_shifted);

endmodule
