#!/usr/bin/env bash
cd .debian || exit
chmod 0755 build/DEBIAN
mkdir -p build/usr/bin
cp ../out/Swift-MesonLSP build/usr/bin
dpkg-deb -Zgzip --build build
cp build.deb /Swift-MesonLSP-debian-stable.deb || exit 1
rm build.deb build/usr/bin/Swift-MesonLSP
cp ../out1/Swift-MesonLSP build/usr/bin
dpkg-deb -Zgzip --build build
cp build.deb /Swift-MesonLSP-debian-testing.deb || exit 1
rm build.deb build/usr/bin/Swift-MesonLSP
cp ../out2/Swift-MesonLSP build/usr/bin
dpkg-deb -Zgzip --build build
cp build.deb /Swift-MesonLSP-debian-unstable.deb || exit 1
rm build.deb build/usr/bin/Swift-MesonLSP
exit 0