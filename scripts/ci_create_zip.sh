#!/usr/bin/env bash
meson setup _release --buildtype release -Db_lto=true
ninja -C _release || exit 1
cp _release/src/mesonlsp mesonlsp
rm -rf _release
meson setup _build --buildtype debug
ninja -C _build || exit 1
ninja -C _build test || exit 1
cp _build/src/mesonlsp mesonlsp.debug
zip -9 "$1".zip mesonlsp.debug mesonlsp
sudo cp "$1".zip / || true
cp "$1".zip / || true
