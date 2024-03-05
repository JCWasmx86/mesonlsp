FROM alpine:latest AS stage1

RUN apk add --no-cache gcc g++ meson curl-static pkgconf util-linux-dev \
    util-linux-static curl-dev libunistring-dev libunistring-static \
    libarchive-static openssl-libs-static libarchive-dev libarchive-static \
    acl-static zlib-static libidn2-static c-ares-static nghttp2-static brotli-static \
    expat-static xz-static xz-dev zstd-static lz4-static bzip2-static zip jemalloc-dev jemalloc-static gtest-dev pkgconf-dev \
    git benchmark-dev mercurial subversion autoconf automake libtool make py3-pip

WORKDIR /app

COPY meson.build meson.options /app/
COPY src /app/src
COPY LSPTests /app/LSPTests
COPY tests /app/tests
COPY subprojects /app/subprojects
RUN git clone https://github.com/libunwind/libunwind
RUN pip install --break-system-packages pygls lsprotocol
WORKDIR /app/libunwind
RUN autoreconf -i
RUN ./configure --prefix=/usr --disable-tests --disable-cxx-exceptions --enable-shared=no --enable-static=yes --enable-minidebuginfo --enable-zlibdebuginfo  --enable-debug-frame
RUN make -j4 install
WORKDIR /app
RUN meson setup _static --default-library=static --prefer-static \
    -Dc_link_args='-static-libgcc -static-libstdc++' \
    -Dcpp_link_args='-static-libgcc -static-libstdc++' -Dstatic_build=true \
    --buildtype=release -Db_lto=true
RUN ninja -C _static
RUN ninja -C _static test
RUN _static/tests/libcxathrow/cxathrowtest
RUN mkdir /app/exportDir
RUN cp _static/src/mesonlsp /app/exportDir
WORKDIR /app/exportDir
RUN zip -9 mesonlsp-alpine-static.zip mesonlsp

FROM scratch AS export-stage
COPY --from=stage1 /app/exportDir/mesonlsp-alpine-static.zip .
