`timescale 1ns/1ps

// 顶层测试模块
module tb_find_first_1;
    // 测试8位模块的信号
    reg [7:0] in_8;
    wire all_zero_8;
    wire [2:0] out_8;
    // 测试16位模块的信号
    reg [15:0] in_16;
    wire all_zero_16;
    wire [3:0] out_16;
    // 测试32位模块的信号
    reg [31:0] in_32;
    wire all_zero_32;
    wire [4:0] out_32;

    // 例化三个模块
    find_first_1_8bit u_8bit(
        .in(in_8),
        .all_zero(all_zero_8),
        .out(out_8)
    );

    find_first_1_16bit u_16bit(
        .in(in_16),
        .all_zero(all_zero_16),
        .out(out_16)
    );

    find_first_1_32bit u_32bit(
        .in(in_32),
        .all_zero(all_zero_32),
        .out(out_32)
    );

    // 生成随机数种子
    integer seed = 2026;
    initial begin
//        $random(seed); // 固定种子，保证测试可复现

        $display("==================== 8位模块测试 ====================");
        test_8bit();
        $display("\n==================== 16位模块测试 ====================");
        test_16bit();
        $display("\n==================== 32位模块测试 ====================");
        test_32bit();
        $finish;
    end

    // 8位模块测试任务：从bit7到bit0降序测试，最后测试全0
    task test_8bit;
        integer i;
        reg [7:0] rand_bits;
    begin
        for(i=7; i>=0; i=i-1) begin
            rand_bits = $random; // 生成随机位（后续位随机）
            in_8 = (1 << i) | (rand_bits & ((1 << i) - 1)); // 第i位为1，低位随机
            #1; // 等待组合逻辑稳定
            $display("in_8 = %08b | 预期第一个1位置 = %0d | 实际out_8 = %0d | all_zero_8 = %b",
                     in_8, i, out_8, all_zero_8);
        end
        // 测试全0
        in_8 = 8'b0000_0000;
        #1;
        $display("in_8 = %08b | 预期全0 = 1 | 实际all_zero_8 = %b",
                 in_8, all_zero_8);
        // 测试全0
        in_8 = 8'b1000_0000;
        #1;
        $display("in_8 = %08b | 预期第一个1位置 = %0d | 实际out_8 = %0d | all_zero_8 = %b",
                 in_8, i, out_8, all_zero_8);

    end
    endtask

    // 16位模块测试任务：从bit15到bit0降序测试，最后测试全0
    task test_16bit;
        integer i;
        reg [15:0] rand_bits;
    begin
        for(i=15; i>=0; i=i-1) begin
            rand_bits = $random;
            in_16 = (1 << i) | (rand_bits & ((1 << i) - 1)); // 第i位为1，低位随机
            #1;
            $display("in_16 = %016b | 预期第一个1位置 = %0d | 实际out_16 = %0d | all_zero_16 = %b",
                     in_16, i, out_16, all_zero_16);
        end
        // 测试全0
        in_16 = 16'b0000_0000_0000_0000;
        #1;
        $display("in_16 = %016b | 预期全0 = 1 | 实际all_zero_16 = %b",
                 in_16, all_zero_16);
    end
    endtask

    // 32位模块测试任务：从bit31到bit0降序测试，最后测试全0
    task test_32bit;
        integer i;
        reg [31:0] rand_bits;
    begin
        for(i=31; i>=0; i=i-1) begin
            rand_bits = $random;
            in_32 = (1 << i) | (rand_bits & ((1 << i) - 1)); // 第i位为1，低位随机
            #1;
            $display("in_32 = %032b | 预期第一个1位置 = %0d | 实际out_32 = %0d | all_zero_32 = %b",
                     in_32, i, out_32, all_zero_32);
        end
        // 测试全0
        in_32 = 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        #1;
        $display("in_32 = %032b | 预期全0 = 1 | 实际all_zero_32 = %b",
                 in_32, all_zero_32);
    end
    endtask

endmodule
