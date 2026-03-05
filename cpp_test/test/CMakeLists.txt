add_subdirectory(log_test)
add_subdirectory(log_test1)

cc_test(NAME compare
        SRCS compare.cpp)
cc_test(NAME graph_visit
        SRCS graph_visit.cpp)
cc_test(NAME read_mem_file
        SRCS read_mem_file.cpp)
cc_test(NAME zip
        SRCS zip.cpp
        STANDARD 23)
cc_test(NAME format
        SRCS format_test.cpp)

cc_test(NAME type_id
        SRCS type_id.cpp)
