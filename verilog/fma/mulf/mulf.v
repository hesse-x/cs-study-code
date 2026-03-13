module mulf(
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [31:0] product
);

// 拆位
wire        sa = a[31];
wire [7:0]  ea = a[30:23];
wire [22:0] ma = a[22:0];

wire        sb = b[31];
wire [7:0]  eb = b[30:23];
wire [22:0] mb = b[22:0];

// 符号位
wire sign = sa ^ sb;

// 尾数扩展隐含 1
wire [23:0] m1 = {1'b1, ma};
wire [23:0] m2 = {1'b1, mb};

// 24x24 乘法（核心，但结构规整）
wire [47:0] m_prod = m1 * m2;

// 指数：ea + eb - 127
wire [7:0] exp_sum  = ea + eb;
wire [7:0] exp_final= exp_sum + 8'sb10000001;

// 规格化（乘法只会出现最高位是 1 或 0，最多右移 1 位）
wire        ovf      = m_prod[47];
wire [7:0]  exp_out  = ovf ? exp_final[7:0] + 1'b1 : exp_final[7:0];
wire [22:0] mant_out = ovf ? m_prod[46:24] : m_prod[45:23];

// 结果
assign product = {sign, exp_out, mant_out};

endmodule
