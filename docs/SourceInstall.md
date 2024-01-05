# Install from source.
Install the dependencies.

1. Clone the repository
2. Execute `meson setup _build --buildtype release -Db_lto=true && ninja -C _build && sudo ninja -C _build install` to get a dynamically linked binary
