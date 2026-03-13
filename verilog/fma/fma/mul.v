module fma_mul(
    input a_sign,
    input [7:0] a_exp,
    input [23:0] a_mant,

    input b_sign,
    input [7:0] b_exp,
    input [23:0] b_mant,

    output t_sign,
    output [7:0] t_exp,
    output [47:0] t_mant
);

assign exp_add = a_exp + b_exp;

wire [47:0] a_pad = {24'b0, a_mant};
wire [47:0] b_pad = {24'b0, b_mant};
wire [47:0] result = a_pad * b_pad;

assign t_sign = a_sign ^ b_sign;
assign t_mant = result[47] ? (result >> 1) : result;
assign t_exp = result[47] ? exp_add + 8'sb10000001 : exp_add + 8'sb10000010;
endmodule
