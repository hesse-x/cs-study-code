module single_booth_encode # (
  parameter shift = 0
) (
  input [23:0] A,
  input [2:0]  b,
  output reg cout,
  output reg [47:0] ret
);

localparam WIDTH = 24;
localparam RET_WIDTH = 48;
reg [WIDTH:0] result;
always @(*) begin
  case(b)
      3'b000: begin
        result = '0;
        cout = 0;
      end
      3'b001: begin
        result = {'0, A};
        cout = 0;
      end
      3'b010: begin
        result = {'0, A};
        cout = 0;
      end
      3'b011: begin
        result = {A, '0};
        cout = 0;
      end
      3'b100: begin
        result = ~{A, '0};
        cout = 1;
      end
      3'b101: begin
        result = ~{'0, A};
        cout = 1;
      end
      3'b110: begin
        result = ~{'0, A};
        cout = 1;
      end
      3'b111: begin
        result = '0;
        cout = 0;
      end
  endcase
  ret = {{(RET_WIDTH-shift-WIDTH-1){cout}}, result, {shift{1'b0}}};
end
endmodule

module booth_encode(
    input [23:0] a,
    input [23:0] b,
    output [47:0] ret_0,
    output [47:0] ret_1,
    output [47:0] ret_2,
    output [47:0] ret_3,
    output [47:0] ret_4,
    output [47:0] ret_5,
    output [47:0] ret_6,
    output [47:0] ret_7,
    output [47:0] ret_8,
    output [47:0] ret_9,
    output [47:0] ret_10,
    output [47:0] ret_11,
    output [47:0] ret_12
);

wire [24:0] pad_b = {b, 1'b0};
wire [11:0] cout;
wire [47:0] temp_ret [11:0];
generate
    genvar i;
    for (i=0; i<12; i=i+1) begin : encode_loop
      single_booth_encode #(.shift(2*i)) u_encode(
        .A(a),
        .b(pad_b[i*2+2:i*2]),
        .cout(cout[i]),
        .ret(temp_ret[i])
      );
    end
endgenerate

assign ret_0 = temp_ret[0];
assign ret_1 = temp_ret[1];
assign ret_2 = temp_ret[2];
assign ret_3 = temp_ret[3];
assign ret_4 = temp_ret[4];
assign ret_5 = temp_ret[5];
assign ret_6 = temp_ret[6];
assign ret_7 = temp_ret[7];
assign ret_8 = temp_ret[8];
assign ret_9 = temp_ret[9];
assign ret_10 = temp_ret[10];
assign ret_11 = temp_ret[11];

assign ret_12 = {24'b0, cout[11], 1'b0, cout[10], 1'b0, cout[9], 1'b0,
                        cout[8], 1'b0, cout[7], 1'b0, cout[6], 1'b0,
                        cout[5], 1'b0, cout[4], 1'b0, cout[3], 1'b0,
                        cout[2], 1'b0, cout[1], 1'b0, cout[0]};

endmodule
