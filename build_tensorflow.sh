#!/usr/bin/env bash
set -e

# configure cuda environmental variables
if [ -e /opt/cuda ]; then
  echo "Using CUDA from /opt/cuda"
  export CUDA_TOOLKIT_PATH=/opt/cuda
elif [ -e /usr/local/cuda ]; then
  echo "Using CUDA from /usr/local/cuda"
  export CUDA_TOOLKIT_PATH=/usr/local/cuda
fi

if [ -e /opt/cuda/include/cudnn.h ]; then
  echo "Using CUDNN from /opt/cuda"
  export CUDNN_INSTALL_PATH=/opt/cuda
elif [ -e /usr/local/cuda/include/cudnn.h ]; then
  echo "Using CUDNN from /usr/local/cuda"
  export CUDNN_INSTALL_PATH=/usr/local/cuda
elif [ -e /usr/include/cudnn.h ]; then
  echo "Using CUDNN from /usr"
  export CUDNN_INSTALL_PATH=/usr
fi

if [ -n "${CUDA_TOOLKIT_PATH}" ]; then
  if [[ -z "${CUDNN_INSTALL_PATH}" ]]; then
    echo "CUDA found but no cudnn.h found. Please install cuDNN."
    exit 1
  fi
  echo "CUDA support enabled"
  cuda_config_opts="--config=opt --config=cuda"
  export TF_NEED_CUDA=1
  export TF_CUDA_COMPUTE_CAPABILITIES=${TF_CUDA_COMPUTE_CAPABILITIES:-"3.5,5.2,6.1,6.2"}
  export TF_CUDA_VERSION="$($CUDA_TOOLKIT_PATH/bin/nvcc --version | sed -n 's/^.*release \(.*\),.*/\1/p')"
  export TF_CUDNN_VERSION="$(sed -n 's/^#define CUDNN_MAJOR\s*\(.*\).*/\1/p' $CUDNN_INSTALL_PATH/include/cudnn.h)"
else
  echo "CUDA support disabled"
  cuda_config_opts=""
  export TF_NEED_CUDA=0
fi

# configure and build
tensorflow/tools/ci_build/builds/configured GPU
bazel build -c opt \
            $cuda_config_opts \
	    --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=0" \
            tensorflow:libtensorflow_cc.so
