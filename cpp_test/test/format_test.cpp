#include <format>
#include <iostream>
#include <vector>

#include <gtest/gtest.h>

TEST(TEST0, TEST0) {
  std::vector<std::string> words = {"hello", "world", "this",
                                    "is",    "a",     "test"};
  constexpr int width = 10; // 设置统一的宽度

  for (const auto &word : words) {
    std::cout << std::format("|{:<{}}|", word, width) << std::endl; // 左对齐
  }

  std::cout << std::endl;
  for (const auto &word : words) {
    std::cout << std::format("|{:>{}}|", word, width) << std::endl; // 右对齐
  }

  std::cout << std::endl;
  for (const auto &word : words) {
    std::cout << std::format("|{:^{}}|", word, width) << std::endl; // 居中对齐
  }

  EXPECT_EQ(std::format("|{:<{}}|", words[0], width), "|hello     |");
  EXPECT_EQ(std::format("|{:>{}}|", words[0], width), "|     hello|");
  EXPECT_EQ(std::format("|{:^{}}|", words[0], width), "|  hello   |");
}
