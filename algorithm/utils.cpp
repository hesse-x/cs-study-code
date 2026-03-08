#include <cmath>
#include <iomanip>
#include <iostream>
#include <vector>

#include "utils.h"
void cmp_ulp(const std::vector<float> &actual, const std::vector<float> &expected) {
    int32_t max_ulp_error = 0.0;
    int32_t first_3ulp_pos = -1;
    std::vector<int32_t> ulp_error(0);

    int64_t error_pos = -1;
    for (size_t i = 0; i < actual.size(); ++i) {
        int32_t ulp = (bitcast_to_int(expected[i]) & 0xffffff) - (bitcast_to_int(actual[i]) & 0xffffff);
        if (ulp < 0)
          ulp = -ulp;
        if (ulp > 0)
          ulp = 32 - __builtin_clz(ulp);
        ulp_error.push_back(ulp);
        if (ulp >= 3 && first_3ulp_pos < 0)
          first_3ulp_pos = i;
        max_ulp_error = std::max(max_ulp_error, ulp);
        if (max_ulp_error == ulp)
          error_pos = i;
    }

    std::cout << "\n";
    std::cout << "ulp errors:\n";
    for (auto v : ulp_error)
      std::cout << v << ", ";
    std::cout << "\n";
    std::cout << "FP32下最大ULP误差：" << std::fixed << std::setprecision(2) << max_ulp_error  << " Pos: " << error_pos
              << "\n";
    std::cout << "第一次误差越界的位置：" << first_3ulp_pos << "\n";
    if (first_3ulp_pos >= 0)
      std::cout << "expected: " << std::fixed << std::setprecision(15) << expected[first_3ulp_pos] << "\tactual: " << actual[first_3ulp_pos] << "\n";
}

void diff3(const std::vector<float> &actual, const std::vector<float> &expected) {
    float max_error = 0.0f;
    int32_t idx = 0;
    for (size_t i = 0; i < actual.size(); ++i) {
      auto diff = std::abs(actual[i] - expected[i]);
      if (diff <= max_error)
        continue;
      max_error = diff;
      idx = i;
    }
    std::cout << "max_error: " << max_error << ", pos: " << idx << "\n";
}

std::vector<float> rel_diff(const std::vector<float> &actual, const std::vector<float> &expected) {
  std::vector<float> res;
  for (size_t i = 0; i < actual.size(); ++i) {
    res.push_back(std::abs((actual[i] - expected[i]) / expected[i]));
  }
  return res;
}

std::vector<float> diff1(const std::vector<float> &actual, const std::vector<float> &expected) {
  std::vector<float> res;
  for (size_t i = 0; i < actual.size(); ++i) {
    res.push_back(std::abs(actual[i] - expected[i]));
  }
  return res;
}

template <>
void print(std::vector<int8_t> val) {
    for (auto v : val) {
        std::cout << static_cast<int>(v) << " ";
    }
    std::cout << "\n";
}
