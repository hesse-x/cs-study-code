module splitf (
    input  wire [31:0]  in,
    
    output wire sign,
    output wire [7:0]   exp,
    output wire [24:0]  mant,
    output wire         is_inf,
    output wire         is_nan,
    output wire         is_zero
);

wire [7:0]  exp_raw     = in[30:23];
wire [22:0] mant_raw    = in[22:0];
wire is_special = exp_raw == 8'hFF;

wire exp_zero  = exp_raw == 8'h00;

assign sign = in[31];
assign exp        = exp_raw;
assign mant     = {1'b0, ~exp_zero, mant_raw};
assign is_inf = is_special & (~|mant_raw);
assign is_nan = is_special & (|mant_raw);
assign is_zero = exp_zero & (~|mant_raw);

endmodule
