#!/usr/bin/env bash
rm -rf .build
swift build --static-swift-stdlib -c debug -Xswiftc -profile-generate -Xswiftc -profile-coverage-mapping
cargo build --release
swift test --enable-code-coverage
sudo cp .build/debug/Swift-MesonLSP /usr/bin
mkdir repos
mkdir /tmp/data
cp .build/debug/codecov/default.profdata /tmp/data/swifttests.profdata
sudo mv /usr/bin/curl curl1
swift test --enable-code-coverage
cp .build/debug/codecov/default.profdata /tmp/data/swifttests2.profdata
sudo mv curl1 /usr/bin/curl
git clone https://github.com/hse-project/hse
cd hse || exit
git checkout ca2bccd60e29a74f2e8b587a9b8d4702c360865c
../.build/debug/Swift-MesonLSP --subproject --path .
mv default.profraw /tmp/data/sb1.profraw
../.build/debug/Swift-MesonLSP --subproject --path .
mv default.profraw /tmp/data/sb2.profraw
../.build/debug/Swift-MesonLSP --subproject-parse meson.build
mv default.profraw /tmp/data/spp.profraw
../.build/debug/Swift-MesonLSP --subproject-parse meson.build
mv default.profraw /tmp/data/spp2.profraw
cd ..
rm -rf hse
cd repos || exit
for i in $(grep https <../scripts/collect_perf_data.py | grep ":" | sed 's/.*":."//g' | sed s/\",//g | sort | uniq); do
	git clone --depth=1 "$i"
done
cd ..
.build/debug/Swift-MesonLSP repos/*/meson.build
mv default.profraw /tmp/data/repos.profraw
./.build/debug/Swift-MesonLSP --test TestCases/*/meson.build || exit
mv default.profraw /tmp/data/tests.profraw
.build/debug/Swift-MesonLSP --wrap Wraps/rustc-demangle.wrap --wrap Wraps/libswiftdemangle.wrap \
	--wrap Wraps/libswiftdemangle2.wrap --wrap Wraps/miniz.wrap \
	--wrap Wraps/turtle.wrap --wrap Wraps/sqlite.wrap \
	--wrap Wraps/pango.wrap --wrap Wraps/turtle2.wrap \
	--wrap Wraps/turtle3.wrap --wrap Wraps/rubberband.wrap \
	--wrap Wraps/pidgin.wrap --wrap Wraps/vorbis.wrap \
	--wrap-output "$PWD/__wrap_target/" --wrap-package-files "$PWD/Wraps/packagefiles" || exit
mv default.profraw /tmp/data/wraps.profraw
rm -rf repos __wrap_target
git clone --depth=1 https://github.com/mesonbuild/wrapdb
cd wrapdb/subprojects || exit
# shellcheck disable=2046
../../.build/debug/Swift-MesonLSP --wrap $(find . -maxdepth 1 -iname "*.wrap" | sed s/^.\\///g | paste -s | sed "s/\t/ --wrap /g") \
	--wrap-output "$PWD/__wrap_target/" --wrap-package-files "$PWD/packagefiles"
cp default.profraw /tmp/data/wrapdb.profraw
cd ../..
rm -rf wrapdb
git clone https://gitlab.freedesktop.org/gstreamer/gstreamer
cd gstreamer || exit
../.build/debug/Swift-MesonLSP --subproject --path .
cp default.profraw /tmp/data/subproject.profraw
rm default.profraw
../.build/debug/Swift-MesonLSP --subproject --path .
cp default.profraw /tmp/data/subproject2.profraw
rm default.profraw
# shellcheck disable=2103
cd ..
rm -rf gstreamer
llvm-profdata-17 merge -sparse /tmp/data/{repos,tests,wraps,wrapdb,subproject,subproject2,sb1,sb2,spp,spp2}.profraw -o default.profdata
llvm-profdata-17 merge /tmp/data/swifttests.profdata /tmp/data/swifttests2.profdata default.profdata -o merged.profdata
llvm-cov-17 export --instr-profile merged.profdata .build/debug/Swift-MesonLSP -format lcov | swift demangle >out.lcov
