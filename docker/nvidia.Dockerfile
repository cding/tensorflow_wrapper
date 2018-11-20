FROM nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04

MAINTAINER compwizk, cding

RUN apt-get update && apt-get install -y --no-install-recommends \
	apt-transport-https ca-certificates curl wget make cmake unzip git \
	autoconf automake libtool g++ \
	build-essential python zip

# Install Protobuf
# [requires] autoconf automake libtool curl make g++ unzip
RUN cd /opt && \
	wget --quiet https://github.com/protocolbuffers/protobuf/releases/download/v3.6.0/protobuf-all-3.6.0.tar.gz && \
	tar -zxf protobuf-all-3.6.0.tar.gz && rm protobuf-all-3.6.0.tar.gz && \
	cd protobuf-3.6.0 && \
	./autogen.sh && ./configure && \
	make && make install && ldconfig && \
	rm -rf /opt/protobuf-3.6.0

# Intall Eigen3
RUN cd /opt && \
	wget --quiet https://bitbucket.org/eigen/eigen/get/fd6845384b86.tar.gz && \
	tar -zxf fd6845384b86.tar.gz && rm /opt/fd6845384b86.tar.gz && \
	mkdir -p /opt/eigen-eigen-fd6845384b86/build && cd /opt/eigen-eigen-fd6845384b86/build && \
	cmake .. && \
	make && make install && \
	rm -rf /opt/eigen-eigen-fd6845384b86 && \
	ln -s /usr/local/include/eigen3 /usr/include/eigen3

# Install GCC-6
RUN apt-get update && apt-get install -y --no-install-recommends software-properties-common && \
	add-apt-repository ppa:ubuntu-toolchain-r/test -y && \
	apt-get update && apt-get install -y --no-install-recommends gcc-6 g++-6 && \
	update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-6 60 --slave /usr/bin/g++ g++ /usr/bin/g++-6

# Install Bazel
# [requires] build-essential openjdk-8-jdk python zip unzip
RUN apt-get update && apt-get install -y --no-install-recommends openjdk-8-jdk && \
	mkdir -p /opt/bazel && cd /opt/bazel && \
	wget --quiet https://github.com/bazelbuild/bazel/releases/download/0.15.0/bazel-0.15.0-dist.zip && \
	unzip bazel-0.15.0-dist.zip && rm bazel-0.15.0-dist.zip && \
	cd /opt/bazel && bash ./compile.sh && mv ./output/bazel /usr/local/bin && rm -rf /opt/bazel

# Install Tensorflow
RUN apt-get update && apt-get install -y --no-install-recommends sudo && \
	cd /opt && git clone https://github.com/cding/tensorflow_wrapper.git && \
	mkdir -p /opt/tensorflow_wrapper/build && \
	cd /opt/tensorflow_wrapper/build && \
	cmake .. && make && make install && \
	rm -rf /opt/tensorflow_wrapper && rm -rf /tmp/tensorflow-* && \
	rm -rf /tmp/cc* && rm -rf /root/.cache
