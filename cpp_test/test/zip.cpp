#include <array>
#include <gtest/gtest.h>
#include <iostream>
#include <ranges>
#include <string_view>
template <std::ranges::range... Args> auto zip(Args &&... args) {
  return std::views::zip(std::forward<Args>(args)...);
}

template <typename T> concept non_range = !std::ranges::range<T>;

template <non_range... Args> auto zip(Args &&... args) {
  return std::tuple<Args...>(std::forward<Args>(args)...);
}

TEST(TEST0, TEST0) {
  std::string_view a("abc");
  std::array<int, 3> b = {1, 2, 3};
  auto view = zip(a, b);
  for (auto val : zip(a, b)) {
    auto [i1, i2] = val;
    EXPECT_EQ(i1, 'a' + i2 - 1);
  }
  auto [v1, v2] = zip(1, 3);
  EXPECT_EQ(v1, 1);
  EXPECT_EQ(v2, 3);
}
