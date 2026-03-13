module fma(
    input  clk,
    input  rst_n,
    input  en,
    input  [1:0] optype, // 00:add, 01:mul, 10:fma
    input  [1:0] inv,
    input  [common::REG_ADDR_WIDTH-1:0] ret_addr_in,
    input  [common::WIDTH-1:0] a,
    input  [common::WIDTH-1:0] b,
    input  [common::WIDTH-1:0] c,

    output reg valid,
    output reg [common::REG_ADDR_WIDTH-1:0] ret_addr_out,
    output reg [common::WIDTH-1:0] ret
);

    //---------------------------------------------------------
    // Stage 1: Split & Multiply
    //---------------------------------------------------------
    wire c_sign;
    wire [common::EXP_WIDTH-1:0] c_exp;
    wire [common::INTERNAL_MANT_WIDTH-1:0] c_mant;

    wire t_sign;
    wire [common::EXP_WIDTH-1:0] t_exp; // 修正位宽一致性
    wire [common::INTERNAL_MANT_WIDTH-1:0] t_mant;

    fma_s1 u_s1(
        .a(a),
        .b(b),
        .c(c),
        .c_sign(c_sign),
        .c_exp(c_exp),
        .c_mant(c_mant), // 修正了重复连接错误
        .t_sign(t_sign),
        .t_exp(t_exp),
        .t_mant(t_mant)  // 修正了重复连接错误
    );

    // S1 -> S2 Pipeline Registers
    reg [1:0] inv_s1;
    reg [common::REG_ADDR_WIDTH-1:0] ret_addr_s1;
    reg t_sign_s1, c_sign_s1;
    reg [common::EXP_WIDTH-1:0] t_exp_s1, c_exp_s1;
    reg [common::INTERNAL_MANT_WIDTH-1:0] t_mant_s1, c_mant_s1;
    reg en_s1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_s1       <= 1'b0;
            inv_s1      <= 2'b0;
            ret_addr_s1 <= '0;
        end else begin
            en_s1       <= en;
            inv_s1      <= inv;
            ret_addr_s1 <= ret_addr_in;
            
            t_sign_s1   <= t_sign;
            t_exp_s1    <= t_exp;
            t_mant_s1   <= t_mant;

            c_sign_s1   <= c_sign;
            c_exp_s1    <= c_exp;
            c_mant_s1   <= c_mant;
        end
    end

    //---------------------------------------------------------
    // Stage 2: Align & Add
    //---------------------------------------------------------
    wire r_sign;
    wire [common::EXP_WIDTH-1:0] r_exp;
    wire [common::INTERNAL_MANT_WIDTH-1:0] r_mant;

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

    // S2 -> S3 Pipeline Registers
    reg r_sign_s2;
    reg [common::EXP_WIDTH-1:0] r_exp_s2;
    reg [common::INTERNAL_MANT_WIDTH-1:0] r_mant_s2;
    reg [common::REG_ADDR_WIDTH-1:0] ret_addr_s2;
    reg en_s2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_s2       <= 1'b0;
            r_sign_s2   <= 1'b0;
            r_exp_s2    <= '0;
            r_mant_s2   <= '0;
            ret_addr_s2 <= '0;
        end else begin
            en_s2       <= en_s1;
            r_sign_s2   <= r_sign;
            r_exp_s2    <= r_exp;
            r_mant_s2   <= r_mant;
            ret_addr_s2 <= ret_addr_s1;
        end
    end

    //---------------------------------------------------------
    // Stage 3: Normalize & Pack
    //---------------------------------------------------------
    wire [common::WIDTH-1:0] final_result;

    fma_s3 u_s3(
        .r_sign(r_sign_s2),
        .r_exp(r_exp_s2),
        .r_mant(r_mant_s2),
        .result(final_result)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid        <= 1'b0;
            ret          <= '0;
            ret_addr_out <= '0;
        end else begin
            valid        <= en_s2;
            ret          <= final_result;
            ret_addr_out <= ret_addr_s2;
        end
    end

endmodule
