`timescale 1ns/1ps

module tb_fma;

    // 只有输入：a b c 三个 32bit 浮点数
    reg [31:0] a, b, c;
    reg [1:0] inv;

    // 只有输出：计算结果 ret
    wire [31:0] ret;

    // 纯组合逻辑 FMA 实例化（只剩 a b c 输入 + ret 输出）
    fma u_dut (
        .a(a),
        .inv(inv),
        .b(b),
        .c(c),
        .ret(ret)
    );

    // 测试任务：赋值 → 等待组合逻辑稳定 → 打印结果
    task test_fma(
        input [31:0] va, vb, vc,
        input [1:0] vinv
    );
        begin
            a = va;
            b = vb;
            c = vc;
            inv = vinv;
            #1;  // 等待 1ns，足够你的 46 级逻辑稳定
            $display("a=%08h | b=%08h | c=%08h | ret=%08h", a, b, c, ret);
        end
    endtask

    // 测试序列
    initial begin
        $display("\n===== 纯组合逻辑 FMA 浮点乘加测试 =====\n");

        // 1.0 * 2.5 + 1.0 = 3.5
        test_fma(32'h3f800000, 32'h40200000, 32'h3f800000, 2'b00);

        // 1.0 * 2.5 - 1.0 = 1.5
        test_fma(32'h3f800000, 32'h40200000, 32'h3f800000, 2'b01);

        // 1.0 * 1.0 - 2.5 = -1.5
        test_fma(32'h3f800000, 32'h3f800000, 32'h40200000, 2'b01);
        // 0.5 * 最小非规格化数 + 0
//        test_fma(32'h3f000000, 32'h00000001, 32'h00000000);
//
//        // 1.0 * 1.0 - 1.0 = 0
//        test_fma(32'h3f800000, 32'h3f800000, 32'hbf800000);
//
//        // 极小值相减产生接近 0 的结果
//        test_fma(32'h03800001, 32'h3f800000, 32'h83800000);

        $display("\n============ 测试完成 ============\n");
        $finish;
    end

    // 生成波形
    initial begin
        $dumpfile("tb_fma.vcd");
        $dumpvars(0, tb_fma);
    end

endmodule
