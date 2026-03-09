#include <iostream>
#include <vector>
#include <cmath>
#include <cstdint>
#include <iomanip>
#include <algorithm>

#include "utils.h"
#include "hardware_math.h"

const double x_min = 0.0;
const double x_max = 1000000.0;
const int num_points = 100;

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
