#include <verilated.h>          // Defines common routines
#include "verilated_vcd_c.h"
#include <iostream>             // Need std::cout
#include "Vfma.h"               // From Verilating "fma.v"
#include <random>
#include "../utils.h"

// --- 固定种子的写法 ---
// 只要这里的数字 12345 不变，每次程序运行生成的浮点数序列将完全一致
unsigned int seed = 12345;
std::mt19937 gen(seed); 

std::uniform_real_distribution<float> dis(-1e1, 1e1);

float gen_fp32() {
  return dis(gen);
}

Vfma *ufma;                      // Instantiation of module

vluint64_t main_time = 0;       // Current simulation time
// This is a 64-bit integer to reduce wrap over issues and
// allow modulus.  You can also use a double, if you wish.

double sc_time_stamp () {       // Called by $time in Verilog
  return main_time;           // converts to double, to match
  // what SystemC does
}

double fma_true(float a, float b, float c) {
  return double(a) * double(b) + double(c);
}

// Id: 743, failed | a: 2.273136(0x40117B10), b: -3.563645(0xC06412C2), c: 4.454924(0x408E8EBC), ret: 3.645726(0x40695394)

struct Value {
public:
  Value(uint32_t i) : val(i) {}
  Value(float f) : val(cast<uint32_t>(f)) {}
  Value(int32_t f) : val(cast<uint32_t>(f)) {}
  Value &operator=(uint32_t i) { val = i; return *this; }
  Value &operator=(int32_t i) { val = cast<uint32_t>(i); return *this; }
  Value &operator=(float f) { val = cast<uint32_t>(f); return *this; }
  operator float() const { return cast<float>(val); }
  operator uint32_t() const { return val; }
  operator int32_t() const { return val; }

private:
  uint32_t val;
};

int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);   // Remember args

  ufma = new Vfma;             // Create instance

  Verilated::traceEverOn(true);
  VerilatedVcdC* tfp = new VerilatedVcdC;
  ufma->trace(tfp, 99);  // Trace 99 levels of hierarchy
  tfp->open("obj_dir/fma.vcd");

  int64_t count = 0;
#if 1
  for (int i = 0; i < 1000; i++) {
    Value a = gen_fp32(),
          b = gen_fp32(),
          c = gen_fp32();
#else
  // Id: 987, failed | a: 3.569344(0x40647020), b: -3.886519(0xC078BCBA), c: -5.815586(0xC0BA1948), ret: -3.687907(0xC06C06AD)
  for (int i = 0; i < 5; i++) {
    Value a = 0x40647020,
          b = 0xC078BCBA,
          c = 0xC0BA1948;
#endif
    ufma->inv = 0b00;
    ufma->rm = 0b000;
    ufma->a = uint32_t(a);
    ufma->b = uint32_t(b);
    ufma->c = uint32_t(c);
    ufma->eval();            // Evaluate model

    const char *result = nullptr;
    if (cast<float>(ufma->ret) == float(fma_true(a, b, c))) {
      result = "success";
    } else {
      result = "failed";
    }
    double expected = fma_true(a, b, c);
    auto [uf, ui] = ulp(cast<float>(ufma->ret), expected);
    printf("ulp: %f, %d\n", uf, ui);
//    auto [a_exp, a_mant] = splitf(a);
//    printf("splitf %f, exp: %01X, mant: %06X\n", a, exp, mant);
//    auto [b_exp, b_mant] = splitf(b);
//    auto [c_exp, c_mant] = splitf(c);
//    printf("mul_mant: %12lX\n", uint64_t(a_mant) * uint64_t(b_mant));
    if (ui > 1 || uf > 1.0) {
      printf("actual: %f, expected: %f(0x%08X)\n", cast<float>(ufma->ret), (float)expected, cast<uint32_t>(float(expected)));
      count++;
    }
    printf("Id: %ld, %s | a: %f(0x%08X), b: %f(0x%08X), c: %f(0x%08X), ret: %f(0x%08X)\n", main_time, result, float(a), int(a), float(b), int(b), float(c), int(c), cast<float>(ufma->ret),  ufma->ret);
    tfp->dump(main_time);
    main_time++;            // Time passes...
  }

  printf("failed count: %ld\n", count);
  ufma->final();               // Done simulating
  //    // (Though this example doesn't get here)
  delete ufma;
  delete tfp;

  if (count != 0)
    return 1;
  return 0;
}

