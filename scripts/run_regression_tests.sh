#!/usr/bin/env bash
# This script will always clone from Github instead of e.g. GNOME Gitlab
# in order to save resources of these projects
export LSPPATH=$PWD/_clang/src/mesonlsp
rm -rf __regressions
mkdir __regressions
cd __regressions || exit
git clone --depth=1 https://gitlab.freedesktop.org/mesa/mesa
cd mesa || exit
$LSPPATH
# Two undefined variables, I assume it's an error on mesa side
[ "$($LSPPATH |& grep 🔴 -c)" -le "2" ] || exit 1
cd .. || exit
git clone --depth=1 https://github.com/systemd/systemd
cd systemd || exit
$LSPPATH
[ "$($LSPPATH |& grep 🔴 -c)" -eq "0" ] || exit 1
cd .. || exit
git clone --depth=1 https://github.com/GNOME/gtk
cd gtk || exit
$LSPPATH
[ "$($LSPPATH |& grep 🔴 -c)" -eq "0" ] || exit 1
cd .. || exit
git clone --depth=1 https://github.com/GNOME/glib
cd glib || exit
$LSPPATH
# Type error in rarely used codepath (Solaris) (Probably) and parameter OOB
[ "$($LSPPATH |& grep 🔴 -c)" -le "2" ] || exit 1
cd .. || exit
git clone --depth=1 https://github.com/GNOME/gnome-builder
cd gnome-builder || exit
$LSPPATH
[ "$($LSPPATH |& grep 🔴 -c)" -eq "0" ] || exit 1
cd .. || exit
git clone --depth=1 https://gitlab.gnome.org/World/fractal.git
cd fractal || exit
$LSPPATH
[ "$($LSPPATH |& grep 🔴 -c)" -eq "0" ] || exit 1
cd .. || exit
git clone --depth=1 https://github.com/GNOME/gitg
cd gitg || exit
$LSPPATH
[ "$($LSPPATH |& grep 🔴 -c)" -eq "0" ] || exit 1
cd .. || exit
git clone --depth=1 https://github.com/JCWasmx86/GNOME-Builder-Plugins
cd GNOME-Builder-Plugins || exit
$LSPPATH
[ "$($LSPPATH |& grep 🔴 -c)" -eq "0" ] || exit 1
cd .. || exit
git clone --depth=1 https://gitlab.com/qemu-project/qemu
cd qemu || exit
$LSPPATH
[ "$($LSPPATH |& grep 🔴 -c)" -eq "0" ] || exit 1
cd .. || exit
git clone --depth=1 https://github.com/harfbuzz/harfbuzz
cd harfbuzz || exit
$LSPPATH
[ "$($LSPPATH |& grep 🔴 -c)" -eq "0" ] || exit 1
cd .. || exit
git clone --depth=1 https://github.com/GNOME/gdk-pixbuf
cd gdk-pixbuf || exit
$LSPPATH
[ "$($LSPPATH |& grep 🔴 -c)" -eq "0" ] || exit 1
cd .. || exit
git clone --depth=1 https://github.com/cisco/libsrtp
cd libsrtp || exit
$LSPPATH
[ "$($LSPPATH |& grep 🔴 -c)" -eq "0" ] || exit 1
cd .. || exit
git clone --depth=1 https://gitlab.freedesktop.org/wayland/wayland
cd wayland || exit
$LSPPATH
[ "$($LSPPATH |& grep 🔴 -c)" -eq "0" ] || exit 1
cd .. || exit
git clone --depth=1 https://gitlab.freedesktop.org/xorg/xserver
cd xserver || exit
$LSPPATH
[ "$($LSPPATH |& grep 🔴 -c)" -eq "0" ] || exit 1
cd .. || exit

echo No errors
cd ..
