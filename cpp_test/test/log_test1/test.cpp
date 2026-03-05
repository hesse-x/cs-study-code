#include "log.h"
#include <chrono>
#include <gtest/gtest.h>
#include <iostream>

using namespace logger;
TEST(TEST0, Benchmark) {
  for (int i = 0; i < 1000; i++) {
    LOG(INFO) << 1 << 2.1f << -3 << -4;
  }
  {
    auto start = std::chrono::steady_clock::now();
    for (int i = 0; i < 1000; i++) {
      LOG(INFO) << 1 << 2.1f << -3 << -4;
    }
    auto end = std::chrono::steady_clock::now();
    double elapsed_secs = double((end - start).count()) / (CLOCKS_PER_SEC);
    std::cout << "Elapsed time: " << elapsed_secs << "s\n";
  }
}

auto fname = __FILE__;
TEST(TEST0, Info) {
  testing::internal::CaptureStderr();
  LOG(INFO) << 1 << 2.1f << -3 << -4;
  auto line = __LINE__ - 1;
  std::string output = testing::internal::GetCapturedStderr();
  auto expected =
      std::format("{}:{} [\033[32mINFO\033[0m] 12.1-3-4\n", fname, line);
  auto pos = output.find(expected);
  ASSERT_TRUE(pos != std::string::npos);
  std::string info = output.substr(pos);
  EXPECT_EQ(info, expected);
}

TEST(TEST0, warning) {
  testing::internal::CaptureStderr();
  LOG(WARNING) << "abc";
  auto line = __LINE__ - 1;
  std::string output = testing::internal::GetCapturedStderr();
  auto expected =
      std::format("{}:{} [\033[33mWARNING\033[0m] abc\n", fname, line);
  auto pos = output.find(expected);
  ASSERT_TRUE(pos != std::string::npos);
  std::string info = output.substr(pos);
  EXPECT_EQ(info, expected);
}

TEST(TEST0, error) {
  testing::internal::CaptureStderr();
  LOG(ERROR) << 2.1 << "abc";
  auto line = __LINE__ - 1;
  std::string output = testing::internal::GetCapturedStderr();
  auto expected =
      std::format("{}:{} [\033[31mERROR\033[0m] 2.1abc\n", fname, line);
  auto pos = output.find(expected);
  ASSERT_TRUE(pos != std::string::npos);
  std::string info = output.substr(pos);
  EXPECT_EQ(info, expected);
}

TEST(TEST0, fatal) {
  std::string death = "death";
  auto expected = std::format("{}:{} \\[\033\\[31mFATAL\033\\[0m] death", fname,
                              __LINE__ + 1);
  EXPECT_DEATH((LOG(FATAL) << death), expected);
}
