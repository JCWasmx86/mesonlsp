#!/usr/bin/env bash
rm -rf .build
swift build --static-swift-stdlib -c debug -Xswiftc -profile-generate -Xswiftc -profile-coverage-mapping
mkdir repos
mkdir /tmp/data
cd repos || exit
for i in $(grep https <../collect_perf_data.py | grep ":" | sed 's/.*":."//g' | sed s/\",//g | sort | uniq); do
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
	--wrap Wraps/turtle3.wrap \
	--wrap-output "$PWD/__wrap_target/" --wrap-package-files "$PWD/Wraps/packagefiles" || exit
mv default.profraw /tmp/data/wraps.profraw
llvm-profdata-15 merge -sparse /tmp/data/{repos,tests,wraps}.profraw -o default.profdata
llvm-cov-15 export --instr-profile default.profdata .build/debug/Swift-MesonLSP -format lcov | swift demangle >out.lcov
