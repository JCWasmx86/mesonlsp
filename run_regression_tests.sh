#!/usr/bin/env bash
# This script will always clone from Github instead of e.g. GNOME Gitlab
# in order to save resources of these projects
swift build -c release --static-swift-stdlib || exit
export LSPPATH=$PWD/.build/release/Swift-MesonLSP
rm -rf __regressions
mkdir __regressions
cd __regressions || exit
git clone --depth=1 https://gitlab.freedesktop.org/mesa/mesa
cd mesa || exit
# Two undefined variables, I assume it's an error on mesa side
[ "$(Swift-MesonLSP meson.build | grep 🔴 -c)" -le "2" ] || exit 1
cd .. || exit
git clone --depth=1 https://github.com/systemd/systemd
cd systemd || exit
[ "$(Swift-MesonLSP meson.build | grep 🔴 -c)" -eq "0" ] || exit 1
cd .. || exit
git clone --depth=1 https://github.com/GNOME/gtk
cd gtk || exit
[ "$(Swift-MesonLSP meson.build | grep 🔴 -c)" -eq "0" ] || exit 1
cd .. || exit
git clone --depth=1 https://github.com/GNOME/glib
cd glib || exit
# Type error in rarely used codepath (Solaris) (Probably)
[ "$(Swift-MesonLSP meson.build | grep 🔴 -c)" -le "1" ] || exit 1
cd .. || exit
git clone --depth=1 https://github.com/GNOME/gnome-builder
cd gnome-builder || exit
[ "$(Swift-MesonLSP meson.build | grep 🔴 -c)" -eq "0" ] || exit 1
cd .. || exit
git clone --depth=1 https://github.com/GNOME/fractal
cd fractal || exit
[ "$(Swift-MesonLSP meson.build | grep 🔴 -c)" -eq "0" ] || exit 1
cd .. || exit
git clone --depth=1 https://github.com/GNOME/gitg
cd gitg || exit
[ "$(Swift-MesonLSP meson.build | grep 🔴 -c)" -eq "0" ] || exit 1
cd .. || exit
git clone --depth=1 https://github.com/JCWasmx86/GNOME-Builder-Plugins
cd GNOME-Builder-Plugins || exit
[ "$(Swift-MesonLSP meson.build | grep 🔴 -c)" -eq "0" ] || exit 1
cd .. || exit
git clone --depth=1 https://gitlab.com/qemu-project/qemu
cd qemu || exit
[ "$(Swift-MesonLSP meson.build | grep 🔴 -c)" -eq "0" ] || exit 1
cd .. || exit
git clone --depth=1 https://github.com/harfbuzz/harfbuzz
cd harfbuzz || exit
[ "$(Swift-MesonLSP meson.build | grep 🔴 -c)" -eq "0" ] || exit 1
cd .. || exit
git clone --depth=1 https://github.com/GNOME/gdk-pixbuf
cd gdk-pixbuf || exit
[ "$(Swift-MesonLSP meson.build | grep 🔴 -c)" -eq "0" ] || exit 1
cd .. || exit
git clone --depth=1 https://github.com/cisco/libsrtp
cd libsrtp || exit
[ "$(Swift-MesonLSP meson.build | grep 🔴 -c)" -eq "0" ] || exit 1
cd .. || exit

echo No errors
cd ..
rm -rf ../__regressions
