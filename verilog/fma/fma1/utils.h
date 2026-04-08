#include <cstdio>
#include <cstddef>
#include <cmath>
template <typename DT, typename ST>
DT cast(ST in) {
  return *(DT*)&in;
}

struct Float {
  uint32_t exp;
  uint32_t mant;
};

static inline Float splitf(float a) {
  uint32_t v = cast<uint32_t>(a);
  uint32_t exp = (v >> 23) & 0xFF;
  uint32_t mant = v & 0x007FFFFF;
  if (exp != 0)
    mant = mant | 0x00800000;
  return Float{.exp = exp, .mant = mant};
}

struct Ulp {
  float ulp_f;
  uint32_t ulp_i;
};
static inline Ulp ulp(float actual, double expected) {
  int32_t actual_i32 = cast<int32_t>(actual);
  int32_t expected_i32 = cast<int32_t>(float(expected));

  uint32_t ulp_i32 = std::abs(actual_i32 - expected_i32);

  double actual_f64 = double(actual);
  uint64_t actual_i64 = cast<uint64_t>(actual_f64);
  uint64_t expected_i64 = cast<uint64_t>(expected);

  double base = cast<double>(expected_i64 & 0xFFF0000000000000);
  double delta = std::abs(expected - actual_f64);

  double ulp_f64 = delta / base;
  ulp_f64 *= std::pow(2, 23);
  return Ulp{.ulp_f = float(ulp_f64), .ulp_i = ulp_i32};
}
