FROM alpine:latest AS stage1

RUN apk add --no-cache gcc g++ meson curl-static pkgconf util-linux-dev \
                       util-linux-static curl-dev libunistring-dev libunistring-static \
                       libarchive-static openssl-libs-static libarchive-dev libarchive-static \
                       acl-static zlib-static libidn2-static c-ares-static nghttp2-static brotli-static \
                       expat-static xz-static zstd-static lz4-static bzip2-static zip jemalloc-dev jemalloc-static gtest-dev

WORKDIR /app

COPY meson.build meson.options /app/
COPY src /app/src
COPY tests /app/tests
COPY subprojects /app/subprojects

RUN meson setup _static --default-library=static --prefer-static \
    -Dc_link_args='-static-libgcc -static-libstdc++' \
    -Dcpp_link_args='-static-libgcc -static-libstdc++' -Dstatic_build=true \
    --buildtype=release -Db_lto=true
RUN ninja -C _static
RUN mkdir /app/exportDir
RUN cp _static/src/Swift-MesonLSP /app/exportDir
WORKDIR /app/exportDir
RUN zip -9 swift-mesonlsp-alpine-static.zip Swift-MesonLSP

FROM scratch AS export-stage
COPY --from=stage1 /app/exportDir/swift-mesonlsp-alpine-static.zip .
