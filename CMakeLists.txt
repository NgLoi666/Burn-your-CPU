cmake_minimum_required(VERSION 3.25)
project(OddPerfectFinder)

# Sử dụng chuẩn C++20 cho std::jthread và các tính năng hiện đại
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(OddPerfectFinder main.cpp)

# Cấu hình tối ưu biên dịch trên Windows (MSVC hoặc MinGW)
if(MSVC)
    target_compile_options(OddPerfectFinder PRIVATE /W4 /O2 /arch:AVX2)
else()
    target_compile_options(OddPerfectFinder PRIVATE -Wall -Wextra -O3 -march=native -pthread)
    target_link_libraries(OddPerfectFinder PRIVATE pthread)
endif()