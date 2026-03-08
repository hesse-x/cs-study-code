#include <iostream>
#include <vector>
#include <cmath>
#include <cstdint>
#include <iomanip>
#include <algorithm>

#include "utils.h"

const double x_min = 0.0;
const double x_max = 1000000.0;
const int num_points = 100;

std::pair<float, uint8_t> extract_fp32_mantissa_exponent(float x) {
    if (std::isnan(x) || std::isinf(x) || x == 0.0f) {
        throw std::invalid_argument("输入不能是NaN/Inf/0");
    }
    // 按位转换，操作FP32二进制
    uint32_t raw = *reinterpret_cast<const uint32_t*>(&x);
    // 提取指数位（bit30~23）
    uint8_t exp_bits = static_cast<uint8_t>((raw >> 23) & 0xFF);
    // 归零指数位，得到尾数m∈[1,2)
    uint32_t mantissa_raw = (raw & 0x807FFFFF) | 0x3F800000; // 指数位设为127
    float mantissa = std::fabs(*reinterpret_cast<float*>(&mantissa_raw));
    return {mantissa, exp_bits};
}

float restore_reciprocal(float reciprocal_m, uint8_t orig_exp_bits) {
    // 核心：1/x = reciprocal_m × 2^(-(orig_exp_bits - 127))
    // 等价于：新指数位 = 127 - (orig_exp_bits - 127) = 254 - orig_exp_bits
    uint8_t new_exp_bits = 253 - orig_exp_bits;

    // 检查新指数位合法性（避免NaN/Inf/非规格化数）
    if (new_exp_bits == 0 || new_exp_bits >= 255) {
        throw std::runtime_error("指数位还原溢出，无法得到有效倒数");
    }

    // 提取reciprocal_m的二进制（此时它的指数位是127，尾数∈(0.5,1]）
    uint32_t rm_raw = *reinterpret_cast<const uint32_t*>(&reciprocal_m);
    // 保留符号位+尾数位，替换为新指数位
    uint32_t sign_mantissa = rm_raw & 0x807FFFFF;
    uint32_t new_raw = sign_mantissa | (static_cast<uint32_t>(new_exp_bits) << 23);

    return *reinterpret_cast<float*>(&new_raw);
}

float hardware_rcp_fp32(float x) {
#if P7
  std::array<float, 8> a = {5.69974746470290938,
                            -14.09053029324782358,
                            19.73336883296406441,
                            -17.12435050518974222,
                            9.42975862054008829,
                            -3.21817810902662371,
                            0.62242512930664573,
                            -0.05224223420402230};
#elif P6
    std::array<float, 7> a = {4.99264126279075526,
                         -10.57536770420885119,
                         12.31980044719922418,
                         -8.52530095606749150,
                         3.50485464419006076,
                         -0.79275664452933103,
                         0.07612257344451137};
#elif P5
    std::array<float, 6> a = {4.28553315243760924, 
                              -7.56019757024730765,
                              7.02754019263710283,
                              -3.63074592965553045,
                              0.98875150382521837,
                              -0.11091851798237302};
#elif P4
    std::array<float, 5> a = {3.57842719673198539,
     -5.04503538170960120,
     3.50305864096220221,
     -1.19828739232705250,
     0.16162029869395844};
#endif

    auto [mantissa, exponent] = extract_fp32_mantissa_exponent(x);

    // 打印中间值（与Python输出格式一致）

    float r = mantissa;
    std::cout << "x, m, e, r: " << std::setprecision(15) << x << " " << mantissa << " " << int(exponent) << " " << r << "\n";

    float p = poly(r, a);
    float result = restore_reciprocal(p, exponent);

    result = result * (2 - x * result);
    result = result * (2 - x * result);
    std::cout << "r, p: "<< std::setprecision(15) << result << " " << p << "\n";

    return result;
}

// ====================== 主函数 ======================
int main() {
    // 设置输出精度（与Python一致）
    std::cout << std::fixed << std::setprecision(15);

    // ====================== 生成FP32测试数据 ======================

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
        y_hardware.push_back(hardware_rcp_fp32(x));
        y_true_fp32.push_back(static_cast<double>(1.0) / static_cast<double>(x));
    }

    // ====================== 计算误差 ======================
    std::vector<float> rel_error = rel_diff(y_hardware, y_true_fp32);
    // std::vector<float> error = diff1(y_hardware, y_true_fp32);

    std::cout << "inputs:" << "\n";
    print(inputs);
    std::cout << "\n";

    std::cout << "outputs:" << "\n";
    print(y_hardware);
    std::cout << "\n";

    std::cout << "real outputs:" << "\n";
    print(y_true_fp32);
    std::cout << "\n";

    std::cout << "rel error:" << "\n";
    print(rel_error);
    std::cout << "\n";

    // ====================== 验证1ULP精度（可选） ======================
    cmp_ulp(y_hardware, y_true_fp32);
    std::cout << "\n";

    return 0;
}
