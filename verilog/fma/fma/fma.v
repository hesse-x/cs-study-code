localparam REG_ADDR_WIDTH = 4;
localparam WIDTH = 32;
localparam MANT_WIDTH = 24;
localparam EXP_WIDTH = 8;
localparam INTERNAL_MANT_WIDTH = 48;
module fma(
    input  clk,
    input  rst_n,
    input  en,
    input  backward_idle_in, // backward pipeline idle info
    input  [1:0] optype, // 00:add, 01:mul, 10:fma, 11:reserve
    input  [1:0] inv,
    input  [REG_ADDR_WIDTH-1:0] ret_addr
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input  [WIDTH-1:0] c,
    output reg idle, // cur module is idle
    output reg backwark_idle_out, // backward pipeline idle info
    output reg valid, // output is valid
    output reg [REG_ADDR_WIDTH-1:0] ret_addr,
    output reg [WIDTH-1:0] ret
);

// stage1: split inputs and latch a/b/c exp/mant
wire c_sign;
wire [EXP_WIDTH-1:0] c_exp;
wire [INTERNAL_MANT_WIDTH-1:0] c_mant;

wire t_sign;
wire [EXP_WIDTH:0] t_exp;
wire [INTERNAL_MANT_WIDTH-1:0] t_mant;

fma_s1 u_s1(
    .a(a),
    .b(b),
    .c(c),
    .c_sign(c_sign),
    .c_exp(c_exp),
    .c_exp(c_mant),
    .t_sign(t_sign),
    .t_exp(t_exp),
    .t_exp(t_mant)
);

reg [1:0] optype_s1;
reg [1:0] inv_s1;
reg [REG_ADDR_WIDTH-1:0] ret_addr_s1;
reg t_sign_s1;
reg [EXP_WIDTH-1:0] t_exp_s1;
reg [INTERNAL_MANT_WIDTH-1:0] t_mant_s1;
reg c_sign_s1;
reg [EXP_WIDTH-1:0] c_exp_s1;
reg [INTERNAL_MANT_WIDTH-1:0] c_mant_s1;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        optype_s1 <= 2'b0;
        ivn_s1 <= 2'b0;
        ret_addr_s1 <= REG_ADDR_WIDTH'b0;
    end
    else begin
        en_s1 <= en;
        optype_s1 <= optype;
        inv_s1 <= inv;
        ret_addr_s1 <= ret_addr;

        t_sign_s1 <= t_sign
        t_exp_s1 <= t_exp;
        t_mant_s1 <= t_mant;

        c_sign_s1 <= c_sign;
        c_exp_s1 <= c_exp;
        c_mant_s1 <= c_mant;
    end
end

// stage2: add c
wire r_sign;
wire [INTERNAL_MANT_WIDTH-1:0] r_mant;
wire [INTERNAL_MANT_WIDTH-1:0] r_exp;
fma_s2 u_s2(
    .inv(inv_s1),

    .t_sign(t_sign_s1),
    .t_exp(t_exp_s1),
    .t_mant(t_mant_s1),

    .c_sign(c_sign_s1),
    .c_exp(c_exp_s1),
    .c_mant(c_mant_s1),

    .r_sign(r_sign),
    .r_exp(r_exp),
    .r_mant(r_mant)
);

reg r_sign_s2;
reg [INTERNAL_MANT_WIDTH-1:0] r_mant_s2;
reg [INTERNAL_MANT_WIDTH-1:0] r_exp_s2;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        r_sign_s2 <= 1'b0;
        r_exp_s2 <= EXP_WIDTH'b0;
        r_mant_s2 <= INTERNAL_MANT_WIDTH'b0;
    end
    else begin
        r_sign_s2 <= r_sign;
        r_exp_s2 <= r_exp;
        r_mant_s2 <= r_mant;
    end
end

// stage3: norm

endmodule
