verilator fma.sv splitf.sv add_compressor.sv find_first1.sv --top-module fma -cc --trace --exe tb_fma.cc --CFLAGS "-std=c++17"

make -C obj_dir -f Vfma.mk

cp obj_dir/Vfma ./a.out
