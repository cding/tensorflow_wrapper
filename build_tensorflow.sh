#!/usr/bin/env bash
set -e

# Configure the build for our CUDA configuration.
export CI_BUILD_PYTHON=python
export LD_LIBRARY_PATH=/usr/local/cuda/extras/CUPTI/lib64:$LD_LIBRARY_PATH
export TF_NEED_CUDA=1
export TF_CUDA_COMPUTE_CAPABILITIES=3.0,3.5,5.2,6.0,6.1
export TF_CUDA_VERSION=$(nvcc --version | sed -n 's/^.*release \(.*\),.*/\1/p')
export TF_CUDNN_VERSION=7

sudo ln -fs /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1
export LD_LIBRARY_PATH=/usr/local/cuda/lib64/stubs:${LD_LIBRARY_PATH}

# configure and build
tensorflow/tools/ci_build/builds/configured GPU
bazel build -c opt --config=cuda \
            --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=0" \
            tensorflow:libtensorflow_cc.so

sudo rm /usr/local/cuda/lib64/stubs/libcuda.so.1
