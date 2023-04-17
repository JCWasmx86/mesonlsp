#!/usr/bin/env bash
cd .debian || exit
chmod 0755 DEBIAN
mkdir -b usr/bin
cp ../out/Swift-MesonLSP usr/bin
dpkg-deb --build .
cp ..deb /Swift-MesonLSP-ubuntu-18.04.deb
rm ..deb usr/bin/Swift-MesonLSP
cp ../out1/Swift-MesonLSP usr/bin
dpkg-deb --build .
cp ..deb /Swift-MesonLSP-ubuntu-20.04.deb
rm ..deb usr/bin/Swift-MesonLSP
cp ../out2/Swift-MesonLSP usr/bin
dpkg-deb --build .
cp ..deb /Swift-MesonLSP-ubuntu-22.04.deb
rm ..deb usr/bin/Swift-MesonLSP
