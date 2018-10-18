# Tensorflow Installation Wrapper

TODO?

# Custom Dockerfile Creation Notes
Some notes for packaging tensorflow into a custom Dockerfile.

## Prerequisites

### Bazel
We need to workaround sandboxing [issues](https://github.com/bazelbuild/bazel/issues/418):
```Dockerfile
RUN echo "build --spawn_strategy=standalone --genrule_strategy=standalone" >>/etc/bazel.bazelrc
```

Install [Bazel](https://docs.bazel.build/versions/master/install-ubuntu.html):
```Dockerfile
RUN apt-get install -y --no-install-recommends curl openjdk-8-jdk \
	&& echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" | sudo tee /etc/apt/sources.list.d/bazel.list \
	&& curl https://bazel.build/bazel-release.pub.gpg | apt-key add - \
	&& apt-get update && apt-get install -y bazel
```
*Note* It seems there are a set of [warnings](https://github.com/bazelbuild/bazel/issues/5599).

### Protobuf
Install [protobuf 3.6.1](https://github.com/protocolbuffers/protobuf/blob/master/src/README.md) (required by tensorflow).
```Dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends autoconf automake libtool curl make g++ unzip
	cd /opt && git clone https://github.com/google/protobuf.git \
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
	&& tar -xzf 3.3.5.tar.gz \
	&& cd eigen-eigen-b3f3d4950030 \
	&& mkdir build \
	&& cd build \
	&& cmake .. \
	&& make \
	&& make install \
	&& rm -rf /opt/3.3.5.tar.gz \
	&& rm -rf /eigen-eigen-b3f3d4950030
```

### Tensorflow
```Dockerfile
RUN apt-get update && apt-get install -y cmake python \
	&& cd /opt && git clone https://github.com/compwizk/tensorflow_wrapper && \
	&& mkdir -p /opt/tensorflow_wrapper/build
	&& cd /opt/tensorflow_wrapper/build
	&& cmake .. \
	&& make \
	&& make install
```