# Install from source.
## Dependencies
### Fedora
```
dnf install zip ninja-build gcc g++ git pip libcurl-devel glibc-static libarchive-devel gtest gtest-devel libpkgconf-devel libuuid-devel uuid python3-pip pkgconf-pkg-config -y
pip install meson
```
### Debian Trixie
```
apt install -y git gcc g++ meson ninja-build libpkgconf-dev libcurl4-openssl-dev pkg-config uuid-dev libarchive-dev libgtest-dev zip
```
### Alpine:Latest
```
apk add --no-cache gcc g++ meson curl-static pkgconf util-linux-dev \
                       util-linux-static curl-dev libunistring-dev libunistring-static \
                       libarchive-static openssl-libs-static libarchive-dev libarchive-static \
                       acl-static zlib-static libidn2-static c-ares-static nghttp2-static brotli-static \
                       expat-static xz-static zstd-static lz4-static bzip2-static zip jemalloc-dev jemalloc-static gtest-dev pkgconf-dev \
                       git
```


1. Clone the repository
2. Execute `meson setup _build --buildtype release -Db_lto=true && ninja -C _build && sudo ninja -C _build install` to get a dynamically linked binary

## Using jemalloc (Recommended!)
Add `-Duse_jemalloc=true` to use the jemalloc allocator. This is recommended.

## Using mimalloc
Add `-Duse_mimalloc=true` to use the mimalloc allocator
