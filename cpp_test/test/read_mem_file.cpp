#include <format>
#include <fstream>
#include <gtest/gtest.h>
#include <iostream>
#include <string>
#include <string_view>
#include <sys/mman.h>
#include <unistd.h>

TEST(TEST0, TEST0) {
  int memfd = memfd_create("decrypted_shared_library", MFD_CLOEXEC);
  if (memfd == -1) {
    perror("memfd_create");
    ASSERT_TRUE(false);
  }

  std::string_view val{"1\nhaha\nzhe shi yi ge nei cun wen jian\n"};
  write(memfd, val.data(), val.size());
  pid_t pid = getpid();
  // read /proc/pid/fd/memfd
  std::string file_name = std::format("/proc/{}/fd/{}", pid, memfd);
  std::ifstream fin(file_name);
  std::string line;
  std::stringstream os;
  while (std::getline(fin, line)) {
    os << line << '\n';
  }
  EXPECT_EQ(os.str(), val);
}
