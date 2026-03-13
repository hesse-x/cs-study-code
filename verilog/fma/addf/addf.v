module addf (
    input  wire [31:0] a,      // 输入A (FP32)
    input  wire [31:0] b,      // 输入B (FP32)
    output wire [31:0] sum     // 输出结果 (FP32)
);

// -------------------------- 步骤1：拆分符号、指数、尾数 --------------------------
wire a_sign;
wire [7:0] a_exp;
wire [24:0] a_mant;
wire a_is_inf;
wire a_is_nan;
wire a_is_zero;
splitf u_split_a(.in(a), .exp(a_exp), .sign(a_sign), .mant(a_mant), .is_inf(a_is_inf), .is_nan(a_is_nan), .is_zero(a_is_zero));

wire b_sign;
wire [7:0] b_exp;
wire [24:0] b_mant;
wire b_is_inf;
wire b_is_nan;
wire b_is_zero;
splitf u_split_b(.in(b), .exp(b_exp), .sign(b_sign), .mant(b_mant), .is_inf(b_is_inf), .is_nan(b_is_nan), .is_zero(b_is_zero));

// -------------------------- 新增：Inf/NaN/零值 特殊处理逻辑 --------------------------
// 1. NaN处理：任意输入为NaN，输出NaN（FP32 NaN标准：指数全1，尾数非0，符号位任意）
wire is_nan_out = a_is_nan | b_is_nan;
wire [31:0] nan_out = 32'h7FC00000;  // 默认QNaN（安静NaN）

// 2. Inf处理：遵循IEEE 754规则
// - Inf + Inf：同符号输出Inf，异符号输出NaN
// - Inf + 非Inf/非NaN：输出Inf（符号与Inf一致）
wire a_inf_only = a_is_inf & ~b_is_inf & ~b_is_nan;
wire b_inf_only = b_is_inf & ~a_is_inf & ~a_is_nan;
wire both_inf = a_is_inf & b_is_inf;
wire inf_sign_same = (a_sign == b_sign) & both_inf;

wire is_inf_out = a_inf_only | b_inf_only | (both_inf & inf_sign_same);
wire [31:0] inf_out = {a_inf_only ? a_sign : b_sign, 8'hFF, 23'h000000};  // Inf格式：指数全1，尾数全0

// 3. 零值处理：
// - 0 + 0：输出0（符号取正，也可按IEEE取第一个操作数符号，这里选正）
// - 0 + 非0/非Inf/非NaN：输出非0数本身
wire both_zero = a_is_zero & b_is_zero;
wire a_zero_only = a_is_zero & ~b_is_zero & ~b_is_inf & ~b_is_nan;
wire b_zero_only = b_is_zero & ~a_is_zero & ~a_is_inf & ~a_is_nan;
wire [31:0] zero_out = 32'h00000000;  // 正零
wire [31:0] non_zero_out = a_zero_only ? b : a;  // 0+非零=非零数

// 4. 特殊情况优先级：NaN > Inf > 零值 > 正常加法
wire use_nan;
wire use_inf;
wire use_zero;
wire use_normal;
assign use_nan = is_nan_out | (both_inf & ~inf_sign_same);  // Inf异号相加也输出NaN
assign use_inf = ~use_nan & is_inf_out;
assign use_zero = ~use_nan & ~use_inf & (both_zero | a_zero_only | b_zero_only);
assign use_normal = ~use_nan & ~use_inf & ~use_zero;

// -------------------------- 步骤2：指数对齐（小指数向大指数对齐） --------------------------
wire exp_a_gt_b = a_exp > b_exp;
wire exp_a_eq_b = a_exp == b_exp;
wire mant_a_gt_b = a_mant > b_mant;
wire a_gt_b = exp_a_gt_b | (exp_a_eq_b & mant_a_gt_b);
wire [7:0] exp_diff = (exp_a_gt_b) ? (a_exp - b_exp) : (b_exp - a_exp);
wire [7:0] exp_large = (exp_a_gt_b) ? a_exp : b_exp;
wire [24:0] mant_large = a_gt_b ? a_mant : b_mant;
wire [24:0] mant_small = a_gt_b ? b_mant : a_mant;
wire sign_large = a_gt_b ? a_sign : b_sign;

// 小尾数右移对齐（补0，保留移位后低位，用于舍入）
wire [24:0] mant_small_shifted = mant_small >> exp_diff;

// -------------------------- 步骤3：尾数加减（无借位+舍入） --------------------------
wire sign_same = (a_sign == b_sign);
wire [24:0] mant_sum = sign_same ? mant_large + mant_small_shifted :
                                   mant_large - mant_small_shifted;
wire sum_sign = sign_large;

// -------------------------- 步骤4：归一化+舍入（保证≤1ulp） --------------------------
// start
wire mant_all_zero;
wire [4:0] first1_pos;
find_first_1_pad_to_32bit#(.W(25)) u_find_first1(.in(mant_sum), .all_zero(mant_all_zero), .out(first1_pos));

wire [3:0] exp_rectification;
assign exp_rectification = first1_pos + 4'b1001;
// end 8 level
// start
wire [23:0] mant_norm = exp_rectification > 0 ? (mant_sum[23:0] >> exp_rectification) :
                              (mant_sum[23:0] << (-exp_rectification));
assign exp_norm = mant_all_zero ? 8'h00 : (exp_large + exp_rectification);
// end 8 level

// -------------------------- 步骤5：最终结果拼接 --------------------------
// 正常加法结果
wire [31:0] normal_sum = {sum_sign, exp_norm, mant_norm[22:0]};

// 选择最终输出：优先特殊情况，再正常加法
assign sum = use_nan    ? nan_out :
             use_inf    ? inf_out :
             use_zero   ? (both_zero ? zero_out : non_zero_out) :
                          normal_sum;

endmodule
