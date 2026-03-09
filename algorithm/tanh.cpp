#include <iostream>
#include <vector>
#include <cmath>
#include <cstdint>
#include <iomanip>
#include <algorithm>

#include "utils.h"
#include "hardware_math.h"

float hardware_tanh_fp32(float x) {
  float e2x = hardware_exp_fp32(2 * x);
  float rcp = hardware_exp_fp32(1 + e2x);
  return 1 - rcp;
}
