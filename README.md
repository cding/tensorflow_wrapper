# set up bazel.
# running bazel inside a `docker build` command causes trouble, cf:
#   https://github.com/bazelbuild/bazel/issues/134
# the easiest solution is to set up a bazelrc file forcing --batch.
RUN echo "startup --batch" >>/etc/bazel.bazelrc
# similarly, we need to workaround sandboxing issues:
#   https://github.com/bazelbuild/bazel/issues/418
RUN echo "build --spawn_strategy=standalone --genrule_strategy=standalone" \
    >>/etc/bazel.bazelrc
# install the most recent bazel release.
RUN mkdir /bazel \
 && cd /bazel \
 && wget https://github.com/bazelbuild/bazel/releases/download/0.12.0/bazel-0.12.0-without-jdk-       installer-linux-x86_64.sh \
 && chmod +x bazel-*.sh \
 && ./bazel-0.12.0-without-jdk-installer-linux-x86_64.sh \
 && cd / \
 && rm -f /bazel/bazel-0.12.0-without-jdk-installer-linux-x86_64.sh

# install protobuf 3.5.0 (required by tensorflow)
RUN git clone https://github.com/google/protobuf.git \
 && cd protobuf \
 && git checkout tags/v3.5.0 \
 && git submodule update --init --recursive \
 && ./autogen.sh \
 && ./configure \
 && make \
 && make install \
 && ldconfig \
 && rm -rf /protobuf
 
# install eigen 3
RUN wget http://mirror.bazel.build/bitbucket.org/eigen/eigen/get/f3a22f35b044.tar.gz \
 && tar -xzvf f3a22f35b044.tar.gz \
 && cd /eigen-eigen-f3a22f35b044 \
 && mkdir build \
 && cd build \
 && cmake .. \
 && make \
 && make install \
 && rm -rf /f3a22f35b044.tar.gz \
 && rm -rf /eigen-eigen-f3a22f35b044
