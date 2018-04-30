cmake_minimum_required(VERSION 3.3)
project(tensorflow_wrapper)

option(${PROJECT_NAME}_build_examples "Build ${PROJECT_NAME} examples." off)

include(ExternalProject)
set(TENSORFLOW_TAG "v1.8.0")
ExternalProject_Add(
  tensorflow
  GIT_REPOSITORY http://github.com/tensorflow/tensorflow.git
  GIT_TAG "${TENSORFLOW_TAG}"
  TMP_DIR "/tmp"
  STAMP_DIR "tensorflow-stamp"
  DOWNLOAD_DIR "tensorflow"
  SOURCE_DIR "tensorflow"
  BUILD_IN_SOURCE 1
  UPDATE_COMMAND ""
  CONFIGURE_COMMAND make -f tensorflow/contrib/makefile/Makefile clean
  COMMAND tensorflow/contrib/makefile/download_dependencies.sh
  COMMAND tensorflow/contrib/makefile/compile_nsync.sh
  BUILD_COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/build_tensorflow.sh
  INSTALL_COMMAND ""
)

# create and setup the interface library for tensorflow
add_library(${PROJECT_NAME} INTERFACE)
add_dependencies(${PROJECT_NAME} tensorflow)

set_target_properties(${PROJECT_NAME} PROPERTIES
  INTERFACE_COMPILE_OPTIONS "-std=c++11;-D_GLIBCXX_USE_CXX11_ABI=0"
)

find_package(Protobuf REQUIRED)
find_package(Eigen3 REQUIRED)

# set the library include directories
set(TF_DEP_DOWNLOADS tensorflow/tensorflow/contrib/makefile/downloads)
set(TF_DEP_INSTALL tensorflow/tensorflow/contrib/makefile/gen)
target_include_directories(${PROJECT_NAME} INTERFACE
  ${Protobuf_INCLUDE_DIRS}
  ${EIGEN3_INCLUDE_DIR}
  ${CMAKE_CURRENT_BINARY_DIR}/tensorflow
  ${CMAKE_CURRENT_BINARY_DIR}/tensorflow/bazel-genfiles
)

set(TF_LIB_DIR ${CMAKE_CURRENT_BINARY_DIR}/tensorflow/bazel-bin/tensorflow)
target_link_libraries(${PROJECT_NAME} INTERFACE
  ${TF_LIB_DIR}/libtensorflow_cc.so 
  ${TF_LIB_DIR}/libtensorflow_framework.so
  ${Protobuf_LIBRARIES}
  ${EIGEN3_LIBS}
)

if(${${PROJECT_NAME}_build_examples})
  add_subdirectory(example)
endif()

# setup package install
set(INCLUDE_DEST "include/${PROJECT_NAME}")
set(LIB_DEST "lib")
set(EXPORT_DEST "lib/${PROJECT_NAME}")

add_library(${PROJECT_NAME}_EXPORT INTERFACE)
set_target_properties(${PROJECT_NAME}_EXPORT PROPERTIES
  INTERFACE_COMPILE_OPTIONS "-std=c++11"
  EXPORT_NAME ${PROJECT_NAME}
)
target_include_directories(${PROJECT_NAME}_EXPORT INTERFACE
  ${CMAKE_INSTALL_PREFIX}/${INCLUDE_DEST}/third_party/eigen3
  ${CMAKE_INSTALL_PREFIX}/${INCLUDE_DEST}/third_party
  ${Protobuf_INCLUDE_DIRS}
  ${EIGEN3_INCLUDE_DIR}
  ${CMAKE_INSTALL_PREFIX}/${INCLUDE_DEST}
)
target_link_libraries(${PROJECT_NAME}_EXPORT INTERFACE
  ${CMAKE_INSTALL_PREFIX}/${LIB_DEST}/libtensorflow_cc.so
  ${CMAKE_INSTALL_PREFIX}/${LIB_DEST}/libtensorflow_framework.so
  ${Protobuf_LIBRARIES}
  ${EIGEN3_LIBS}
)

# install all header files
install(
  DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/tensorflow/tensorflow/cc
  DESTINATION ${INCLUDE_DEST}/tensorflow
  FILES_MATCHING PATTERN "*.h"
)
install(
  DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/tensorflow/tensorflow/core
  DESTINATION ${INCLUDE_DEST}/tensorflow
  FILES_MATCHING PATTERN "*.h"
)
install(
  DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/tensorflow/bazel-genfiles/tensorflow
  DESTINATION ${INCLUDE_DEST}
  FILES_MATCHING PATTERN "*.h"
)
install(
  DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/tensorflow/bazel-genfiles/external
  DESTINATION ${INCLUDE_DEST}
  FILES_MATCHING PATTERN "*.h"
)
install(
  DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/tensorflow/third_party
  DESTINATION ${INCLUDE_DEST}
  FILES_MATCHING PATTERN "*"
                 PATTERN "Makefile*"  EXCLUDE
                 PATTERN "*unittest*" EXCLUDE
                 PATTERN "*.o"        EXCLUDE
                 PATTERN "*.so"       EXCLUDE
                 PATTERN "*.so.*"     EXCLUDE
                 PATTERN "*.a"        EXCLUDE
                 PATTERN "*.tbz"      EXCLUDE
                 PATTERN "*.tgz"      EXCLUDE
                 PATTERN "*.tar"      EXCLUDE
                 PATTERN "*.tar.*"    EXCLUDE
                 PATTERN "*.zip"      EXCLUDE
)
# (Note that we cannot simply include all *.h or *.hpp files, since e.g., eigen
# does not use file extensions for header files.)
install(
  DIRECTORY ${EIGEN3_INCLUDE_DIR}
  DESTINATION ${INCLUDE_DEST}/third_party
  FILES_MATCHING PATTERN "*"
                 PATTERN "Makefile*"  EXCLUDE
                 PATTERN "*unittest*" EXCLUDE
                 PATTERN "*.o"        EXCLUDE
                 PATTERN "*.so"       EXCLUDE
                 PATTERN "*.so.*"     EXCLUDE
                 PATTERN "*.a"        EXCLUDE
                 PATTERN "*.tbz"      EXCLUDE
                 PATTERN "*.tgz"      EXCLUDE
                 PATTERN "*.tar"      EXCLUDE
                 PATTERN "*.tar.*"    EXCLUDE
                 PATTERN "*.zip"      EXCLUDE
)

install(FILES
  ${TF_LIB_DIR}/libtensorflow_cc.so
  ${TF_LIB_DIR}/libtensorflow_framework.so
  DESTINATION ${LIB_DEST}
)
install(TARGETS ${PROJECT_NAME}_EXPORT EXPORT ${PROJECT_NAME} DESTINATION ${LIB_DEST})
install(FILES ${PROJECT_NAME}-config.cmake DESTINATION ${EXPORT_DEST})
install(EXPORT ${PROJECT_NAME} DESTINATION ${EXPORT_DEST})

