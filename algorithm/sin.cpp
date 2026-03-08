#include <iostream>
#include <vector>
#include <cmath>
#include <cstdint>
#include <iomanip>
#include <algorithm>

#include "utils.h"
const double pi  = M_PI;
const double x_min = 0;
const double x_max = pi;
const int num_points = 100;

std::array<float, 5> a = {0.99999997659034112,
-0.16666647634828072,
0.00833289982608440,
-0.00019800897920578,
0.00000259048880198};

float reduce_rad_sin(float x) {
    float pi_f = float(pi);
    // 1. 先算 x/pi（你要求必须先做这步）
    float n_pi = x / pi_f;
    // 2. 找最近偶数 k，等价于 x 模 2pi
    float k = std::round(n_pi / 2.0f) * 2.0f;
    // 3. 得到 [-pi, pi] 内的等价角
    float r = x - k * pi_f;
    // 4. 映射到 [-pi/2, pi/2]，保持 sin 等价
    const float pi_2 = pi_f * 0.5f;
    if (r > pi_2) {
        r = pi_f - r;
    } else if (r < -pi_2) {
        r = -pi_f - r;
    }
    return r;
}
float hardware_sin_fp32(float x) {
    float r = reduce_rad_sin(x);
    float sq_r = r * r;
    std::cout << "x, r: " << std::setprecision(15) << x << "\t" << r << "\n";

    // 步骤3：霍纳法则计算多项式（全程FP32乘加）
    float p = poly(sq_r, a);
    p *= r;

    float result = p;
    std::cout << std::setprecision(15) << result << " " << p << "\n";
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
        y_hardware.push_back(hardware_sin_fp32(x));
        y_true_fp32.push_back(std::sin(static_cast<double>(x)));
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

    std::cout << "outputs:" << "\n";
    print(y_true_fp32);
    std::cout << "\n";

    // ====================== 验证1ULP精度（可选） ======================
    cmp_ulp(y_hardware, y_true_fp32);
    std::cout << "\n";

    return 0;
}
