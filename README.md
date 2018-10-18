# Tensorflow Installation Wrapper

TODO?

# Custom Dockerfile Creation Notes
Some notes for packaging tensorflow into a custom Dockerfile.

## Prerequisites

### Bazel
**Note:** Running Bazel inside a `docker build` command causes [trouble](https://github.com/bazelbuild/bazel/issues/134). The easiest solution is to set up a bazelrc file forcing --batch:
```Dockerfile
RUN echo "startup --batch" >>/etc/bazel.bazelrc
```

Similarly, we need to workaround sandboxing [issues](https://github.com/bazelbuild/bazel/issues/418):
```Dockerfile
RUN echo "build --spawn_strategy=standalone --genrule_strategy=standalone" >>/etc/bazel.bazelrc
```

Install Bazel:
```Dockerfile
RUN mkdir /opt/bazel \
	&& cd /opt/bazel \
	&& wget https://github.com/bazelbuild/bazel/releases/download/0.12.0/bazel-0.12.0-without-jdk-installer-linux-x86_64.sh \
	&& chmod +x bazel-*.sh \
	&& ./bazel-0.12.0-without-jdk-installer-linux-x86_64.sh \
	&& cd / \
	&& rm -f /opt/bazel/bazel-0.12.0-without-jdk-installer-linux-x86_64.sh
```

### Protobuf
Install protobuf 3.6.1 (required by tensorflow)
```Dockerfile
RUN cd /opt && git clone https://github.com/google/protobuf.git \
	&& cd protobuf \
	&& git checkout tags/v3.6.1 \
	&& git submodule update --init --recursive \
	&& ./autogen.sh \
	&& ./configure \
	&& make \
	&& make install \
	&& ldconfig \
	&& rm -rf /opt/protobuf
```

### Eigen
Install Eigen 3
```Dockerfile
RUN cd /opt && wget http://bitbucket.org/eigen/eigen/get/3.3.5.tar.gz \
	&& tar -xzvf 3.3.5.tar.gz \
	&& cd eigen-eigen-b3f3d4950030 \
	&& mkdir build \
	&& cd build \
	&& cmake .. \
	&& make \
	&& make install \
	&& rm -rf /opt/3.3.5.tar.gz \
	&& rm -rf /eigen-eigen-b3f3d4950030
```
