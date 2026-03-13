`timescale 1ns/1ps

module tb_fma;

    reg clk;
    reg rst_n;
    reg en;
    reg [1:0] optype;
    reg [1:0] inv;
    reg [common::REG_ADDR_WIDTH-1:0] ret_addr_in;
    reg [31:0] a, b, c;

    wire valid;
    wire [common::REG_ADDR_WIDTH-1:0] ret_addr_out;
    wire [31:0] ret;

    // 实例化 FMA
    fma u_dut (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .optype(optype),
        .inv(inv),
        .ret_addr_in(ret_addr_in),
        .a(a),
        .b(b),
        .c(c),
        .valid(valid),
        .ret_addr_out(ret_addr_out),
        .ret(ret)
    );

    // 时钟生成
    initial clk = 0;
    always #5 clk = ~clk;

    // 任务：发送一组激励
    task drive_input(
        input [31:0] va, vb, vc,
        input [1:0]  v_inv,
        input [3:0]  addr
    );
        begin
            @(negedge clk);
            en <= 1;
            a  <= va;
            b  <= vb;
            c  <= vc;
            inv <= v_inv;
            ret_addr_in <= addr;
            optype <= 2'b10; // FMA mode
            @(negedge clk);
            en <= 0;
        end
    endtask

    initial begin
        // 初始化
        rst_n = 0;
        en = 0;
        a = 0; b = 0; c = 0;
        inv = 0;
        ret_addr_in = 0;

        repeat(5) @(posedge clk);
        rst_n = 1;
        repeat(2) @(posedge clk);

        // --- Case 1: 普通规格化数乘加 (1.0 * 2.5 + 1.0 = 3.5) ---
        // 1.0 = 32'h3f80_0000, 2.5 = 32'h4020_0000
        drive_input(32'h3f80_0000, 32'h4020_0000, 32'h3f80_0000, 2'b00, 4'h1);

        // --- Case 2: 输入包含非规格化数 (Subnormal Input) ---
        // 极小的非规格化数: 32'h0000_0001 (min positive subnormal)
        // 0.5 * Subnormal + 0
        drive_input(32'h3f00_0000, 32'h0000_0001, 32'h0000_0000, 2'b00, 4'h2);

        // --- Case 3: 覆盖 inv 信号 (1.0 * 1.0 - 1.0 = 0) ---
        // inv[1]=1 代表对 c 取反，即 a*b + (-c)
        drive_input(32'h3f80_0000, 32'h3f80_0000, 32'h3f80_0000, 2'b10, 4'h3);

        // --- Case 4: a*b 约等于 -c，产生非规格化结果 ---
        // a = 1.000...01 * 2^-120
        // b = 1.0
        // c = -1.000...00 * 2^-120
        // 结果应该落在指数全0的区域
        // a = 32'h0380_0001 (exp=7), b = 32'h3f80_0000 (exp=127)
        // a*b exp approx 7. c = 32'h8380_0000
        drive_input(32'h0380_0001, 32'h3f80_0000, 32'h8380_0000, 2'b00, 4'h4);

        // 等待流水线清空
        repeat(10) @(posedge clk);
        $display("Test Sequence Finished.");
        $finish;
    end

    // 监视器：打印输出结果
    initial begin
        $monitor("Time=%0t | Valid=%b | Addr=%h | Result=%h", 
                 $time, valid, ret_addr_out, ret);
    end
    initial begin
        $dumpfile("tb_fma.vcd");
        // 第一步：导出普通信号（标量/矢量）
        $dumpvars(0, tb_fma);
    end


endmodule
