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
    std::cout << std::fixed << std::setprecision(15);

    // ====================== 生成FP32测试数据 ======================
    std::vector<float> inputs = logspace(x_min, x_max, num_points);

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
