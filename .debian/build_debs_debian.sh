#!/usr/bin/env bash
cd .debian || exit
chmod 0755 build/DEBIAN
mkdir -p build/usr/bin
cp ../out/Swift-MesonLSP build/usr/bin
dpkg-deb --build build
cp build.deb /Swift-MesonLSP-debian-stable.deb
rm build.deb usr/bin/Swift-MesonLSP
cp ../out1/Swift-MesonLSP build/usr/bin
dpkg-deb --build .
cp build.deb /Swift-MesonLSP-ubuntu-debian-testing.deb
rm .deb usr/bin/Swift-MesonLSP
cp ../out2/Swift-MesonLSP build/usr/bin
dpkg-deb --build .
cp build.deb /Swift-MesonLSP-ubuntu-debian-unstable.deb
rm build.deb usr/bin/Swift-MesonLSP
