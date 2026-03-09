#include <iostream>
#include <vector>
#include <cmath>
#include <cstdint>
#include <iomanip>
#include <algorithm>

#include "utils.h"
#include "hardware_math.h"

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
