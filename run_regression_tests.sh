#!/usr/bin/env bash
swift build -c release --static-swift-stdlib || exit
alias gc="git clone --depth=1"
export LSPPATH=$PWD/.build/release/Swift-MesonLSP
rm -rf __regressions
mkdir __regressions
cd __regressions || exit
git clone --depth=1 https://gitlab.freedesktop.org/mesa/mesa
cd mesa || exit
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
[ "$(Swift-MesonLSP meson.build | grep 🔴 -c)" -le "4" ] || exit 1
cd .. || exit
echo No errors
rm -rf ../__regressions
