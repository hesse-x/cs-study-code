#include <string_view>
#include <iostream>

template <typename T>
struct A {
  T val;
};

using B = A<float>;

struct C : public A<double> {};

template <typename T>
constexpr auto printType() {
  std::string_view name;
  name = __PRETTY_FUNCTION__;
//  return name;
  std::size_t start = name.find_first_of('=') + 2;
  std::size_t end = name.size() - 1;
  name = std::string_view{ name.data() + start, end - start };
  start = name.rfind("::");
  return start == std::string_view::npos ? name : std::string_view{
    name.data() + start + 2, name.size() - start - 2
  };
}

int main() {
  std::cout << printType<A<int>>() << "\n";
  std::cout << printType<B>() << "\n";
  std::cout << printType<C>() << "\n";
}
