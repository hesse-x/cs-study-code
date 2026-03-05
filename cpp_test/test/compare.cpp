#include <compare>
#include <gtest/gtest.h>
#include <iostream>
#include <ranges>
#include <string>

struct A {
  std::strong_ordering operator<=>(const A &other) const {
    auto len = std::min(str.size(), other.str.size());
    for (int i = 0; i < len; i++) {
      if (str[i] < other.str[i])
        return std::strong_ordering::less;
      if (str[i] > other.str[i])
        return std::strong_ordering::greater;
    }
    if (str.size() > other.str.size())
      return std::strong_ordering::greater;
    if (str.size() < other.str.size())
      return std::strong_ordering::less;
    return std::strong_ordering::equal;
  }
  bool operator==(const A &other) const { return (*this <=> other == 0); }
  std::string str;
};
TEST(TEST0, TEST0) {
  auto res = int(3) <=> int(2);
  EXPECT_TRUE(res > 0);

  A a1{"ab"}, a2{"b"};
  EXPECT_TRUE(a1 < a2);
  EXPECT_FALSE(a1 > a2);
  EXPECT_FALSE(a1 == a2);
}
