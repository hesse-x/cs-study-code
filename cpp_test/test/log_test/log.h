#include <sstream>

#define EXPORT __attribute__((visibility("default")))
namespace logger {
enum class Level { INFO = 0, WARNING = 1, ERROR = 2, FATAL = 3 };

class EXPORT Logger : public std::basic_ostringstream<char> {
public:
  Logger(Level level, const char *fname, int line)
      : line(line), fname(fname), level(level) {}
  Logger(Logger &&) = default;

  Logger() = delete;
  Logger(const Logger &) = delete;
  ~Logger() override;

protected:
  void print();

private:
  int line;
  const char *fname;
  Level level;
};

class EXPORT LoggerFatal : public Logger {
public:
  using Logger::Logger;
  ~LoggerFatal() override;
};
} // namespace logger

#define __LOG_INFO ::logger::Logger(::logger::Level::INFO, __FILE__, __LINE__)
#define __LOG_WARNING                                                          \
  ::logger::Logger(::logger::Level::WARNING, __FILE__, __LINE__)
#define __LOG_ERROR ::logger::Logger(::logger::Level::ERROR, __FILE__, __LINE__)
#define __LOG_FATAL                                                            \
  ::logger::LoggerFatal(::logger::Level::FATAL, __FILE__, __LINE__)

#define LOG(LEVEL) __LOG_##LEVEL
