#include <iostream>
#include <vector>

#include <gtest/gtest.h>

class TypeID {
public:
  template <typename T> static int getID() {
    static int id = assignId();
    return id;
  }

private:
  static int assignId() {
    static int a = 0;
    return a++;
  }
};

class Base {
public:
  Base(int id) : id(id) {}
  int typeID() const { return id; }

private:
  int id;
};

class A : public Base {
public:
  A() : Base(TypeID::getID<A>()) {}
  int a;
};

class B : public Base {
public:
  B() : Base(TypeID::getID<B>()) {}
  double b;
};

class C : public Base {
public:
  C() : Base(TypeID::getID<C>()) {}
  int a;
  float b;
  double c;
};

int size(int id) {
  if (id == TypeID::getID<A>())
    return sizeof(A);
  if (id == TypeID::getID<B>())
    return sizeof(B);
  if (id == TypeID::getID<C>())
    return sizeof(C);
  std::abort();
  return 0;
}

TEST(TEST0, TEST0) {
  std::vector<char> buffer;
  A a;
  B b;
  C c;
  buffer.insert(buffer.end(), (const char *)&a, (const char *)&a + sizeof(A));
  buffer.insert(buffer.end(), (const char *)&b, (const char *)&b + sizeof(B));
  buffer.insert(buffer.end(), (const char *)&c, (const char *)&c + sizeof(C));

  std::cout << "A id: " << TypeID::getID<A>() << "\n";
  std::cout << "B id: " << TypeID::getID<B>() << "\n";
  std::cout << "C id: " << TypeID::getID<C>() << "\n";

  const char *ptr = buffer.data();
  auto id = ((const Base *)ptr)->typeID();
  std::cout << "element 1: " << id << "\n";

  ptr += size(id);
  id = ((const Base *)ptr)->typeID();
  std::cout << "element 2: " << id << "\n";

  ptr += size(id);
  id = ((const Base *)ptr)->typeID();
  std::cout << "element 3: " << id << "\n";
}
