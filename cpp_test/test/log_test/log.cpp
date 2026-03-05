#include "log.h"
#include <cstdio>
#include <string_view>

#define GREEN "\033[32m"
#define RED "\033[31m"
#define YELLOW "\033[33m"
#define RESET "\033[0m"

static constexpr std::string_view levelStr[4] = {GREEN "INFO", YELLOW "WARNING",
                                                 RED "ERROR", RED "FATAL"};

namespace logger {
void Logger::print() {
  const auto info = view();
  const auto idx = static_cast<int>(level);
  const auto size = static_cast<int>(info.size());
  fprintf(stderr,
          "%s:%d"
          " ["
          "%s" RESET "] "
          "%.*s\n",
          fname, line, levelStr[idx].data(), size, info.data());
}
Logger::~Logger() { print(); }

LoggerFatal::~LoggerFatal() {
  print();
  std::abort();
}
} // namespace logger
