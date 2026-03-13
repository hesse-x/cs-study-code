module fma_s3(
    input r_sign,
    input [common::EXP_WIDTH-1:0] r_exp,
    input [common::INTERNAL_MANT_WIDTH-1:0] r_mant,

    output [common::WIDTH-1:0] result
);

    wire [5:0] first1_pos;
    wire all_zero;

    // 这里的 find_first1 假设返回的是最高位 1 的索引 (例如 bit 47 是 1，则返回 47)
    find_first1_pad_to_64bit #(.W(48)) u_find(
        .in(r_mant),
        .all_zero(all_zero),
        .out(first1_pos)
    );

    // 目标是将第一个 1 移到第 23 位 (规格化浮点数的隐藏位位置)
    // shift_amt > 0 表示右移, < 0 表示左移
    wire can_normed = (r_exp > 23) | (46 < r_exp +  first1_pos);
    wire signed [6:0] shift_amt = $signed({1'b0, first1_pos}) - 7'd23;
    wire signed [6:0] exp_corr = $signed({1'b0, first1_pos}) - 7'd46;

    wire [common::INTERNAL_MANT_WIDTH-1:0] normalized_mant;
    assign normalized_mant = (shift_amt >= 0) ? (r_mant >> shift_amt) : (r_mant << (-shift_amt));

    // 指数调整
    wire [common::EXP_WIDTH-1:0] final_exp = all_zero ? 8'h0 : (r_exp + $unsigned(exp_corr));
    
    wire [6:0] denormed_shift = r_exp > 0 ? r_exp - 1 : r_exp;
    wire [common::INTERNAL_MANT_WIDTH-1:0] denormed_mant = (r_mant << denormed_shift) >> 23;
    // 拼接结果: {符号, 指数, 尾数(去掉隐藏位)}
    assign result = can_normed ? {r_sign, final_exp, normalized_mant[22:0]} : {r_sign, 8'h00, denormed_mant[22:0]};

endmodule
