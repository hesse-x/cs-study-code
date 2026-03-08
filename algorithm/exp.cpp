#include <iostream>
#include <vector>
#include <cmath>
#include <cstdint>
#include <iomanip>
#include <algorithm>

#include "utils.h"

float hardware_exp_fp32(float x) {
    constexpr float INV_LN2_FP32 = 1.0 / std::log(2.0);
#if P7
    std::array<float, 8> a = {0.99999999999916556,
     1.00000000076555073,
     0.50000000248426679,
     0.16666659932689812,
     0.04166645696609354,
     0.00833472714661210,
     0.00139321868125452,
     0.00019070911826619};
#elif P6
     std::array<float, 7> a = {0.99999999991756217,
     1.00000003957572026,
     0.50000001727171162,
     0.16666406641144513,
     0.04166607142225115,
     0.00837589439356256,
     0.00139568423807980};
#elif P5
     std::array<float, 6> a = {1.00000007604888363,
     1.00000006517205731,
     0.49998863555311329,
     0.16666323982100059,
     0.04191814639235722,
     0.00838122890791970};
#elif P4
     std::array<float, 5> a = {1.00000000235365727,
          0.99999764950312364,
          0.49999898142455335,
          0.16697969509955338,
          0.04173970528452483};
#endif

    // 步骤1：输入转换为FP32
    float x_fp32 = x;

    // 步骤2：范围规约（全程FP32运算）
    float x_scaled = x_fp32 * INV_LN2_FP32;
    float k = std::round(x_scaled);
    float r = x_fp32 - (k * std::log(2));

    // 打印中间值（与Python输出格式一致）
    std::cout << std::setprecision(15) << x << " " << k << " " << r << "\n";

    // 步骤3：霍纳法则计算多项式（全程FP32乘加）
    float p = poly(r / 2, a);
    p *= p;

    // 步骤4：指数位偏移（硬件级位操作）
    // 将poly转为32位无符号整数
    uint32_t uint_val = *reinterpret_cast<uint32_t*>(&p);
    // 提取指数位（FP32：第23~30位）
    uint32_t exponent = (uint_val & 0x7F800000) >> 23;
    // 计算新指数（偏移k，限制在有效范围）
    int new_exponent = static_cast<int>(exponent) + static_cast<int>(k);
    // new_exponent = std::clamp(new_exponent, 1, 254);
    // 替换指数位
    uint32_t new_uint = (uint_val & 0x807FFFFF) | (static_cast<uint32_t>(new_exponent) << 23);
    // 转回FP32
    float result = *reinterpret_cast<float*>(&new_uint);
//    result = result * (2 + x - result);
//    result = result * (x - result  + 2 + (result - 1) * (result - 1) / 2);

    std::cout << std::setprecision(15) << result << " " << p << "\n";

    return result;
}

// ====================== 主函数 ======================
int main() {
    // 设置输出精度（与Python一致）
    std::cout << std::fixed << std::setprecision(15);

    // ====================== 生成FP32测试数据 ======================
    const double x_min = 0.0;
    const double x_max = 80.0;
    const int num_points = 100;

    std::vector<float> x_log_fp32;
    std::vector<float> inputs;

    // 对数均匀取点（复刻Python的linspace+pow逻辑）
    double log_min = std::log10(x_min + 1e-6);
    double log_max = std::log10(x_max);
    double step = (log_max - log_min) / (num_points - 1);

    for (int i = 0; i < num_points; ++i) {
        double x_log = log_min + i * step;
        x_log_fp32.push_back(x_log);
        inputs.push_back(std::pow(10.0, x_log));
    }

    // ====================== 计算硬件exp结果和真实值 ======================
    std::vector<float> y_hardware;
    std::vector<float> y_true_fp32;

    for (float x : inputs) {
        y_hardware.push_back(hardware_exp_fp32(x));
        y_true_fp32.push_back(std::exp(static_cast<double>(x)));
    }

    // ====================== 计算误差 ======================
    std::vector<float> rel_error = rel_diff(y_hardware, y_true_fp32);
    std::vector<float> error = diff1(y_hardware, y_true_fp32);

    std::cout << "inputs:" << "\n";
    print(inputs);
    std::cout << "\n";

    std::cout << "outputs:" << "\n";
    print(y_hardware);
    std::cout << "\n";

    std::cout << "rel error:" << "\n";
    print(rel_error);
    std::cout << "\n";

    // ====================== 验证1ULP精度（可选） ======================
    cmp_ulp(y_hardware, y_true_fp32);
    std::cout << "\n";

    return 0;
}
