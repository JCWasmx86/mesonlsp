#!/usr/bin/env bash
meson setup _release --buildtype release -Db_lto=true
# shellcheck disable=SC2086
ninja -C _release $2 || exit 1
./_release/tests/libcxathrow/cxathrowtest
cp _release/src/mesonlsp mesonlsp
rm -rf _release
meson setup _build --buildtype debug
# shellcheck disable=SC2086
ninja -C _build $2 || exit 1
# shellcheck disable=SC2086
ninja -C _build test $2 || exit 1
./_build/tests/libcxathrow/cxathrowtest
cp _build/src/mesonlsp mesonlsp.debug
zip -9 "$1".zip mesonlsp.debug mesonlsp
sudo cp "$1".zip / || true
cp "$1".zip / || true
