# Tensorflow Installation Wrapper

A small project using CMake to build tensorflow C++ from source (Google's github tagged releases) on x86_64 and aarch64 (specifically arm64v8).

# Build Requirements
You can easily package these components into a Dockerfile if you want to go that route.

>>>
If you are using a TX2, just be sure to package your nvidia, cuda, and cudnn drivers/libs into the image as well. Also, in the `utils` folder there is a script that creates the scratch space necessary to build tensorflow on the TX2 target. The script contains the repo link if you want more information on how that works.
>>>

## Prerequisites

### Bazel
Grab [Bazel 0.15.0](https://github.com/bazelbuild/bazel/releases/download/0.15.0/bazel-0.15.0-installer-linux-x86_64.sh) for tensorflow 1.11. If you are building on aarch64, you will need to [build bazel](https://docs.bazel.build/versions/master/install-ubuntu.html) from [source](https://github.com/bazelbuild/bazel/releases/download/0.15.0/bazel-0.15.0-dist.zip) on the target device or setup bazel to build a cross-compiled binary (not-recommended).

```Dockerfile
RUN mkdir -p /opt/bazel && cd /opt/bazel && \
	wget --quiet https://github.com/bazelbuild/bazel/releases/download/0.15.0/bazel-0.15.0-dist.zip && \
	unzip bazel-0.15.0-dist.zip && rm bazel-0.15.0-dist.zip && \
	cd /opt/bazel && bash ./compile.sh && mv ./output/bazel /usr/local/bin && rm -rf /opt/bazel
```

### Protobuf
Install [protobuf 3.6.1](https://github.com/protocolbuffers/protobuf/blob/master/src/README.md) (required by tensorflow).
```Dockerfile
RUN cd /opt && \
	wget --quiet https://github.com/protocolbuffers/protobuf/releases/download/v3.6.1/protobuf-all-3.6.1.tar.gz && \
	tar -zxf protobuf-all-3.6.1.tar.gz && rm protobuf-all-3.6.1.tar.gz && \
	cd protobuf-3.6.1 && \
	./autogen.sh && ./configure && \
	make && make install && ldconfig && \
	rm -rf /opt/protobuf-3.6.1
```

### Eigen
Install Eigen 3
```Dockerfile
RUN cd /opt && \
	wget --quiet http://bitbucket.org/eigen/eigen/get/3.3.5.tar.gz && \
	tar -zxf 3.3.5.tar.gz && rm /opt/3.3.5.tar.gz && \
	mkdir -p /opt/eigen-eigen-b3f3d4950030/build && cd /opt/eigen-eigen-b3f3d4950030/build && \
	cmake .. && \
	make && make install && \
	rm -rf /opt/eigen-eigen-b3f3d4950030
```

### GCC-6
```Dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends software-properties-common && \
	add-apt-repository ppa:ubuntu-toolchain-r/test -y && \
	apt-get update && apt-get install -y --no-install-recommends gcc-6 g++-6 && \
	update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-6 60 --slave /usr/bin/g++ g++ /usr/bin/g++-6
```

### Tensorflow
```Dockerfile
COPY tensorflow_wrapper /opt/tensorflow_wrapper
RUN mkdir -p /opt/tensorflow_wrapper/build && \
	cd /opt/tensorflow_wrapper/build && \
	cmake .. && make && make install
```

>>>
On TX2, Make sure your `/usr/lib/aarch64-linux-gnu/libcuda.so.1` exists and is linked to `/usr/lib/aarch64-linux-gnu/libcuda.so` otherwise the build will fail.
>>>
