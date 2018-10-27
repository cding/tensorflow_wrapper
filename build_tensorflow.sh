#!/usr/bin/env bash
set -e

export CI_BUILD_PYTHON=python

if [ "$(uname -m)" = "x86_64" ]; then
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
        export TF_CUDNN_VERSION="$(sed -n 's/^#define CUDNN_MAJOR\s*\(.*\).*/\1/p' $CUDNN_PATH/include/cudnn.h)"

        sudo ln -fs ${CUDA_PATH}/lib64/stubs/libcuda.so ${CUDA_PATH}/lib64/stubs/libcuda.so.1
        export LD_LIBRARY_PATH=${CUDA_PATH}/lib64/stubs:${LD_LIBRARY_PATH}
        tensorflow/tools/ci_build/builds/configured GPU
    else
        echo "CUDA support disabled"
        config_opts=""
        export TF_NEED_CUDA=0
    fi

# This should probably be a bit mroe specific since deviceQuery is compiled against TX2
elif [ "$(uname -m)" = "aarch64" ]; then

    export PYTHON_BIN_PATH=$(which $PYTHON)
    export USE_DEFAULT_PYTHON_LIB_PATH=1
    export TF_NEED_JEMALLOC=1
    export TF_NEED_GCP=0
    export TF_NEED_HDFS=0
    export TF_NEED_S3=0
    export TF_NEED_AWS=0
    export TF_NEED_KAFKA=0
    export TF_ENABLE_XLA=0
    export TF_NEED_GDR=0
    export TF_NEED_VERBS=0
    export TF_NEED_OPENCL=0
    export TF_NEED_OPENCL_SYCL=0
    export TF_NEED_CUDA=1
    export TF_CUDA_VERSION="9.0"
    export CUDA_TOOLKIT_PATH="$(dirname $(dirname $(which nvcc)))"
    export CUDNN_INSTALL_PATH="/usr/lib/aarch64-linux-gnu"
    export TF_CUDNN_VERSION="$(ls -l $CUDNN_INSTALL_PATH | grep -oP '(?<=libcudnn.so.)\s*(\d+)\.(\d*)\.(\d*)\s*' | head -n 1)"
    export TF_NEED_TENSORRT=1
    export TENSORRT_INSTALL_PATH="$CUDNN_INSTALL_PATH"
    export TF_NCCL_VERSION=1.3
    export TF_CUDA_COMPUTE_CAPABILITIES="5.3,6.2"
    export TF_CUDA_CLANG=0
    export GCC_HOST_COMPILER_PATH="$(which gcc)"
    export TF_NEED_MPI=0
    export CC_OPT_FLAGS="-march=native"
    export TF_SET_ANDROID_WORKSPACE=0
    export TF_NEED_NGRAPH=0

    bash ./configure
    git apply -p1 ../jetson.patch
    config_opts="--config=cuda"

else
    echo "Unsupported architecture detected: $(uname -m)"
    exit 1
fi

# configure and build
bazel build -c opt $config_opts \
            tensorflow:libtensorflow_cc.so \
            tensorflow/tools/graph_transforms:transform_graph \
            tensorflow/tools/graph_transforms:summarize_graph
