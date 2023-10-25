#!/usr/bin/env bash
swift build --static-swift-stdlib || exit 1
cp .build/debug/Swift-MesonLSP Swift-MesonLSP.debug
rm -rf .build/
swift test || exit 1
rm -rf .build/
swift build -c release --static-swift-stdlib || exit 1
cp .build/release/Swift-MesonLSP Swift-MesonLSP
zip -9 "$1".zip Swift-MesonLSP.debug Swift-MesonLSP
sudo cp "$1".zip /