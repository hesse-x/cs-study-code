#include <span>
#include <vector>

inline static int32_t bitcast_to_int(float v) {
  return reinterpret_cast<int32_t&>(v);
}

void cmp_ulp(std::span<float> actual, std::span<float> expected);
std::vector<float> rel_diff(std::span<float> actual, std::span<float> expected);
std::vector<float> diff1(std::span<float> actual, std::span<float> expected);
void diff3(std::span<float> actual, std::span<float> expected);

template <typename T>
void print(std::vector<T> val) {
    for (auto v : val) {
        std::cout << v << " ";
    }
    std::cout << "\n";
}


