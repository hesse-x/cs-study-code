#include <vector>

inline static int32_t bitcast_to_int(float v) {
  return reinterpret_cast<int32_t&>(v);
}

void cmp_ulp(const std::vector<float> &actual, const std::vector<float> &expected);
std::vector<float> rel_diff(const std::vector<float> &actual, const std::vector<float> &expected);
std::vector<float> diff1(const std::vector<float> &actual, const std::vector<float> &expected);
void diff3(const std::vector<float> &actual, const std::vector<float> &expected);

template <typename T>
void print(std::vector<T> val) {
    for (auto v : val) {
        std::cout << v << " ";
    }
    std::cout << "\n";
}

template <size_t PN>
float poly(float x, std::array<float, PN> a) {
  float res = a[PN - 1];
  for (int64_t i = PN - 1; i > 0; i--) {
    res = res * x + a[i - 1];
  }
  return res;
}

std::vector<float> linspace(double s, double e, int64_t n);
std::vector<float> logspace(double s, double e, int64_t n);

void print_hex(float v);
