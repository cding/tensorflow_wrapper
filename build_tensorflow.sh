#!/usr/bin/env bash
set -e

# Default Settings
export CI_BUILD_PYTHON=python
export PYTHON_BIN_PATH="$(which $PYTHON)"
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
export TF_SET_ANDROID_WORKSPACE=0
export TF_NEED_NGRAPH=0
export TF_NEED_ROCM=0
export TF_CUDA_CLANG=0
export GCC_HOST_COMPILER_PATH="$(which gcc)"
export TF_NEED_MPI=0
export CC_OPT_FLAGS="-march=native"
export BUILD_PY_WHEEL=0

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
        export TF_NCCL_VERSION=1.3
        export TF_NEED_CUDA=1
        export TF_CUDA_COMPUTE_CAPABILITIES=3.0,3.5,5.2,6.0,6.1
        export TF_CUDA_VERSION=$(nvcc --version | sed -n 's/^.*release \(.*\),.*/\1/p')
        export TF_CUDNN_VERSION="$(sed -n 's/^#define CUDNN_MAJOR\s*\(.*\).*/\1/p' $CUDNN_PATH/include/cudnn.h)"
        export CUDA_TOOLKIT_PATH="$(dirname $(dirname $(which nvcc)))"
        export CUDNN_INSTALL_PATH="/usr/lib/x86_64-linux-gnu"
        export TF_NEED_TENSORRT=0

        # Check if running as root
        if [ "$EUID" -ne 0 ]; then
            sudo ln -fs ${CUDA_PATH}/lib64/stubs/libcuda.so ${CUDA_PATH}/lib64/stubs/libcuda.so.1
        else
            ln -fs ${CUDA_PATH}/lib64/stubs/libcuda.so ${CUDA_PATH}/lib64/stubs/libcuda.so.1
        fi
        export LD_LIBRARY_PATH=${CUDA_PATH}/lib64/stubs:${LD_LIBRARY_PATH}
        tensorflow/tools/ci_build/builds/configured GPU
    else
        echo "CUDA support disabled"
        config_opts=""
        export TF_NEED_CUDA=0
    fi

    bash ./configure

elif [[ "$(uname -r)" == *"tegra"* ]] && [[ "$(uname -m)" = "aarch64" ]]; then
    echo "Tegra system detected..."

    export TF_NEED_CUDA=1

    if [ "$(uname -r)" = "4.4.38-tegra" ]; then
        # Check specific to TX2 JP 3.3
        export TF_CUDA_VERSION="9.0"
        export TF_CUDA_COMPUTE_CAPABILITIES="6.2,5.3"
    else
        # Xavier board is 108+ by default
        export TF_CUDA_VERSION="10.0"
        export TF_CUDA_COMPUTE_CAPABILITIES="7.2,6.2,5.3"
    fi

    export CUDA_TOOLKIT_PATH="$(dirname $(dirname $(which nvcc)))"
    export CUDNN_INSTALL_PATH="/usr/lib/aarch64-linux-gnu"
    export TF_CUDNN_VERSION="$(ls -l $CUDNN_INSTALL_PATH | grep -oP '(?<=libcudnn.so.)\s*(\d+)\.(\d*)\.(\d*)\s*' | head -n 1)"
    export TF_NEED_TENSORRT=1
    export TENSORRT_INSTALL_PATH="$CUDNN_INSTALL_PATH"
    export TF_NCCL_VERSION=1.3

    bash ./configure
    git apply -p1 ../jetson.patch
    config_opts="--config=cuda"

elif [[ "$(uname -m)" = "aarch64" ]]; then
    bash ./configure
    git apply -p1 ../jetson.patch
    config_opts=""

else
    echo "Unsupported architecture detected: $(uname -m)"
    exit 1
fi

# Configure and build
bazel build -c opt $config_opts \
            tensorflow/tools/pip_package:build_pip_package \
            tensorflow:libtensorflow_cc.so \
            tensorflow/tools/graph_transforms:transform_graph \
            tensorflow/tools/graph_transforms:summarize_graph

./bazel-bin/tensorflow/tools/pip_package/build_pip_package ./tmp/tensorflow_pkg
