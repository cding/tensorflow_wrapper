#!/usr/bin/env bash
set -e

export CI_BUILD_PYTHON=python

# Check if CUDA is installed.
if [ -e /usr/local/cuda ]; then
    echo "Using CUDA from /usr/local/cuda"
    export CUDA_PATH=/usr/local/cuda
fi

# Check if CUDNN is installed.
if [ -e /usr/local/cuda/include/cudnn.h ]; then
    echo "Using CUDNN from /usr/local/cuda"
    export CUDNN_PATH=/usr/local/cuda
elif [ -e /usr/include/cudnn.h ]; then
    echo "Using CUDNN from /usr"
    export CUDNN_PATH=/usr
fi
if [ -n "${CUDA_PATH}" ]; then
    if [[ -z "${CUDNN_PATH}" ]]; then
        echo "CUDA found but no cudnn.h found. Please install cuDNN."
        exit 1
    fi
    echo "CUDA support enabled"
    config_opts="--config=cuda"

    # Configure the build for our CUDA configuration.
    export LD_LIBRARY_PATH=${CUDA_PATH}/extras/CUPTI/lib64:$LD_LIBRARY_PATH
    export TF_NEED_CUDA=1
    export TF_CUDA_COMPUTE_CAPABILITIES=3.0,3.5,5.2,6.0,6.1
    export TF_CUDA_VERSION=$(nvcc --version | sed -n 's/^.*release \(.*\),.*/\1/p')
    export TF_CUDNN_VERSION="$(sed -n 's/^#define CUDNN_MAJOR\s*\(.*\).*/\1/p' $CUDNN_INSTALL_PATH/include/cudnn.h)"

    sudo ln -fs ${CUDA_PATH}/lib64/stubs/libcuda.so ${CUDA_PATH}/lib64/stubs/libcuda.so.1
    export LD_LIBRARY_PATH=${CUDA_PATH}/lib64/stubs:${LD_LIBRARY_PATH}
    tensorflow/tools/ci_build/builds/configured GPU
else
    echo "CUDA support disabled"
    config_opts=""
    export TF_NEED_CUDA=0
fi

# configure and build
bazel build -c opt $config_opts \
            tensorflow:libtensorflow_cc.so \
            tensorflow/python/tools:freeze_graph \
            tensorflow/tools/graph_transforms:transform_graph \
            tensorflow/tools/graph_transforms:summarize_graph
