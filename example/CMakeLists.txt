cmake_minimum_required(VERSION 3.3 FATAL_ERROR)

add_executable(example example.cpp)
find_package(CUDA REQUIRED)
target_link_libraries(example tensorflow_wrapper ${CUDA_LIBRARIES})

