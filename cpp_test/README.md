用于学习C++、cmake、代码检查工具的仓库

```shell
mkdir build
cd build
cmake ../build_tools/cmake
make
make test
```

```shell
test
├── compare.cpp           # <=>运算符测试
├── graph_visit.cpp       # 基于协程的有向无环图的遍历
├── log_test              # 简易log系统
│   ├── CMakeLists.txt
│   ├── log.cpp
│   ├── log.h
│   └── test.cpp
├── log_test1             # 基于模板的log系统(concept/std::format/编译时常量字符串生成)
│   ├── CMakeLists.txt
│   ├── log.h
│   └── test.cpp
├── read_mem_file.cpp     # 将内存映射成文件不创建真实磁盘文件的情况下获得一个可以读写的虚拟文件
└── zip.cpp               # ranges zip功能测试
```
