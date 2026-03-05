#include <format>
#include <functional>
#include <sstream>
#include <utility>

namespace logger {
class Logger;
class LoggerFatal;

enum class Level { INFO = 0, WARNING = 1, ERROR = 2, FATAL = 3 };

namespace impl {
template <typename D> struct LoggerBase;

template <typename LhsT, typename RhsT> struct LogUtil;

template <typename T> concept LoggerType = std::is_base_of_v<LoggerBase<T>, T>;

template <typename T> concept LogUtilType = requires {
  typename std::remove_cvref_t<T>::LhsTy;
  typename std::remove_cvref_t<T>::RhsTy;
  requires std::is_same_v<std::remove_cvref_t<T>,
                          LogUtil<typename std::remove_cvref_t<T>::LhsTy,
                                  typename std::remove_cvref_t<T>::RhsTy>>;
};

template <typename T> concept LogType = LoggerType<T> || LogUtilType<T>;

template <typename LhsT, typename RhsT> struct LogUtil {
  using LhsTy = LhsT;
  using RhsTy = RhsT;
  LogUtil(LhsTy &&lhs, RhsTy &&rhs)
      : lhs(std::forward<LhsTy>(lhs)), rhs(std::forward<RhsTy>(rhs)) {
    static_assert(LogType<LhsTy> && "lhs must be logger or logutil");
  }
  template <typename T> auto operator<<(T &&val) {
    return LogUtil<LogUtil<LhsTy, RhsTy>, T>(std::move(*this),
                                             std::forward<T>(val));
  }

  LhsTy lhs;
  RhsTy rhs;
};

template <typename T> constexpr size_t getLogUtilSize() {
  size_t ret{0};
  using Type = std::remove_cvref_t<T>;
  if constexpr (LogUtilType<Type>) {
    ret += getLogUtilSize<typename Type::LhsTy>();
    ret += getLogUtilSize<typename Type::RhsTy>();
  } else if constexpr (LoggerType<Type>) {
    return 0;
  } else {
    return 1;
  }
  return ret;
}

template <size_t idx, typename T> constexpr auto get(const T &message) {
  static_assert(idx < getLogUtilSize<T>());
  if constexpr (idx == 0) {
    if constexpr (LogUtilType<T>) {
      return message.rhs;
    } else {
      return message;
    }
  } else {
    return get<idx - 1>(message.lhs);
  }
}

template <LogType T> constexpr const auto &getLogger(const T &message) {
  if constexpr (LoggerType<T>) {
    return message;
  } else {
    return getLogger(message.lhs);
  }
}

template <int N> consteval auto generateFormatStr() {
  std::array<char, 2 * N + 1> ret;
  for (int i = 0; i < 2 * N; i += 2) {
    ret[i] = '{';
    ret[i + 1] = '}';
  }
  ret.back() = '\0';
  return ret;
}

template <typename M, std::size_t... I>
decltype(auto) print_impl(M &&t, std::index_sequence<I...>) {
  static constexpr auto len = sizeof...(I);
  static constexpr auto formatStr = generateFormatStr<len>();
  static constexpr std::string_view s(formatStr.data(), formatStr.size());
  return std::format(s, get<len - I - 1>(std::forward<M>(t))...);
}

template <LogUtilType M> decltype(auto) print(M &&t) {
  constexpr auto len = getLogUtilSize<M>();
  return print_impl(std::forward<M>(t), std::make_index_sequence<len>{});
}

class LogFinalize {
private:
#define GREEN "\033[32m"
#define RED "\033[31m"
#define YELLOW "\033[33m"
#define RESET "\033[0m"
  static constexpr std::string_view levelStr[4] = {
      GREEN "INFO", YELLOW "WARNING", RED "ERROR", RED "FATAL"};

public:
  template <LogType T> void operator&(T &&logger) {
    if constexpr (LoggerType<T>) {
      const auto idx = static_cast<int>(logger.level);
      const auto fname = logger.fname;
      const auto line = logger.line;
      fprintf(stderr,
              "%s:%d"
              " ["
              "%s" RESET "]"
              " \n",
              fname, line, levelStr[idx].data());
      using Type = std::remove_cvref_t<T>;
      if constexpr (std::is_same_v<LoggerFatal, Type>)
        std::abort();

    } else if constexpr (LogUtilType<T>) {
      const auto info = print(logger);
      const auto size = static_cast<int>(info.size());

      const auto &l = getLogger(logger);
      const auto idx = static_cast<int>(l.level);
      const auto fname = l.fname;
      const auto line = l.line;
      fprintf(stderr,
              "%s:%d"
              " ["
              "%s" RESET "]"
              " %.*s\n",
              fname, line, levelStr[idx].data(), size, info.data());
      using Type = std::remove_cvref_t<decltype(l)>;
      if constexpr (std::is_same_v<LoggerFatal, Type>)
        std::abort();
    }
  }
};
#undef GREEN
#undef RED
#undef YELLOW
#undef RESET

template <typename D> struct LoggerBase {
  template <typename T> auto operator<<(T &&val) && {
    return ::logger::impl::LogUtil<D, T>(static_cast<D &&>(std::move(*this)),
                                         std::forward<T>(val));
  }

  LoggerBase(Level level, const char *fname, int line)
      : line(line), fname(fname), level(level) {}
  LoggerBase(LoggerBase &&) = default;
  ~LoggerBase() = default;

  LoggerBase() = delete;
  LoggerBase(const LoggerBase &) = delete;

  int line;
  const char *fname;
  Level level;
};
} // namespace impl

class Logger : public ::logger::impl::LoggerBase<Logger> {
  using LoggerBase::LoggerBase;
};

class LoggerFatal : public ::logger::impl::LoggerBase<LoggerFatal> {
public:
  using LoggerBase::LoggerBase;
};
} // namespace logger

#define __LOG_INFO                                                             \
  ::logger::impl::LogFinalize{} &                                              \
      ::logger::Logger(::logger::Level::INFO, __FILE__, __LINE__)
#define __LOG_WARNING                                                          \
  ::logger::impl::LogFinalize{} &                                              \
      ::logger::Logger(::logger::Level::WARNING, __FILE__, __LINE__)
#define __LOG_ERROR                                                            \
  ::logger::impl::LogFinalize{} &                                              \
      ::logger::Logger(::logger::Level::ERROR, __FILE__, __LINE__)
#define __LOG_FATAL                                                            \
  ::logger::impl::LogFinalize{} &                                              \
      ::logger::LoggerFatal(::logger::Level::FATAL, __FILE__, __LINE__)

#define LOG(LEVEL) __LOG_##LEVEL
