cmake_minimum_required(VERSION 3.5)
project(cpp_test)
 
# 用于测试因此必须开启测试
enable_testing()

# 设置C++标准
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 设置生成 compile_commands.json
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# 配置clang-tidy
# set(CMAKE_CXX_CLANG_TIDY "${CLANG_TIDY_EXE}")
# add_custom_target(
#     clang-tidy
#     COMMAND run-clang-tidy -fix -format -quiet -j 4
#     COMMENT "Running clang-tidy"
# )

# 配置iwyu
# find_program(IWYU_PATH NAMES include-what-you-use include-what-you-use)
# add_custom_target(
#     iwyu
#     COMMAND python3 ${CMAKE_SOURCE_DIR}/build_tools/iwyu_tool.py -p . -- -Xiwyu --transitive_includes_only -Xiwyu --cxx17ns -Xiwyu --mapping_file=${CMAKE_SOURCE_DIR}/build_tools/iwyu.imp
#     COMMENT "Running iwyu"
# )

add_custom_target(
    clang-format
    COMMAND bash ${CMAKE_SOURCE_DIR}/build_tools/clang_format.sh ${CMAKE_SOURCE_DIR}
    COMMENT "Running clang-format"
)

# Find the Google Test package
find_package(GTest REQUIRED)

# 定义源文件目录变量
set(PROJECT_SOURCE_DIR ${CMAKE_SOURCE_DIR}/../../)

# 添加工程的根目录到头文件搜索路径
include_directories(${PROJECT_SOURCE_DIR})
include(${CMAKE_CURRENT_SOURCE_DIR}/macros.cmake)

add_subdirectory(${PROJECT_SOURCE_DIR}/test ${CMAKE_BINARY_DIR}/test)
