// FP32 浮点数乘以 2^n 模块（纯组合逻辑，IEEE 754 单精度）
// 功能：ret = x * 2^n
// 输入：
//   x：待缩放的 FP32 数（32bit）
//   n      ：2^n 的指数（8bit 补码，范围 -128~127）
// 输出：
//   ret：缩放后的 FP32 数（32bit）
module scalbnf (
    input  wire [31:0]  x,    // 输入 FP32 数
    input  wire [7:0]   n,          // 2^n 的指数（补码表示，n∈[-128,127]）
    output wire [31:0]  ret    // 输出 FP32 数
);

// -------------------------- 步骤1：拆分 FP32 输入的各个字段 --------------------------
wire        sign;       // 符号位（bit31）
wire [7:0]  exp;        // 指数位（bit30~23）
wire [22:0] mantissa;   // 尾数位（bit22~0）

// 直接组合逻辑拆分，无时序延迟
assign sign     = x[31];
assign exp      = x[30:23];
assign mantissa = x[22:0];

// -------------------------- 步骤2：计算新指数（处理加减 n） --------------------------
// 扩展位宽至 9bit 防止溢出：exp(8bit无符号) + n(8bit补码) → 9bit有符号结果
wire [8:0] exp_ext;    // 9bit 扩展指数（bit8 为符号位）
assign exp_ext = {1'b0, exp} + {{1{n[7]}}, n}; // n 符号扩展到 9bit 后与 exp 相加

// -------------------------- 步骤3：判断指数溢出/下溢 --------------------------
// FP32 指数合法范围：1~254（对应 2^-126 ~ 2^127）
// 溢出（>254）：返回无穷大；下溢（<1）：返回 0；正常：使用新指数
wire exp_overflow;  // 指数溢出标记
wire exp_underflow; // 指数下溢标记

assign exp_overflow  = (exp_ext > 9'd254); // 指数超过最大值 254
assign exp_underflow = (exp_ext < 9'd1);   // 指数低于最小值 1

// -------------------------- 步骤4：生成最终输出 --------------------------
wire [7:0]  exp_new;    // 处理后的新指数
wire [22:0] mantissa_new; // 处理后的新尾数

// 赋值新指数：溢出→255（无穷大的指数），下溢→0（0的指数），正常→取低8bit
assign exp_new = exp_overflow  ? 8'hFF :
                 exp_underflow ? 8'h00 :
                 exp_ext[7:0];

// 赋值新尾数：溢出→0（无穷大的尾数），下溢→0（0的尾数），正常→保持原尾数
assign mantissa_new = (exp_overflow | exp_underflow) ? 23'd0 : mantissa;

// 拼接最终 FP32 输出：符号位始终不变
assign ret = {sign, exp_new, mantissa_new};

endmodule
