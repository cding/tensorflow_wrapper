cmake_minimum_required(VERSION 3.3 FATAL_ERROR)
project(tensorflow_example)

find_package(CUDA)
find_package(tensorflow_wrapper)

if (NOT CUDA_FOUND)
	set(CUDA_LIBRARIES "")
endif(NOT CUDA_FOUND)

add_executable(example example.cpp)
target_link_libraries(example tensorflow_wrapper ${CUDA_LIBRARIES})
