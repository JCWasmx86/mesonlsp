#!/usr/bin/env sh
rm -rf __wrap_target
mkdir __wrap_target
swift build -c release --static-swift-stdlib || exit
export LSPPATH="$PWD/.build/release/Swift-MesonLSP"
$LSPPATH --wrap Wraps/rustc-demangle.wrap --wrap Wraps/libswiftdemangle.wrap \
						--wrap Wraps/libswiftdemangle2.wrap --wrap Wraps/miniz.wrap \
						--wrap Wraps/turtle.wrap --wrap Wraps/sqlite.wrap \
						--wrap Wraps/pango.wrap \
						--wrap-output "$PWD/__wrap_target/" --wrap-package-files "$PWD/Wraps/packagefiles"|| exit
cd __wrap_target || exit
cd libswiftdemangle || exit
if test -f ".git/refs/heads/main"; then
	echo "Shouldn't have refs/heads/main"
	exit 1
fi
cd ../libswiftdemangle2 || exit
if grep -v -q "e96565e27f95865830626f5d8a081b69cfe5ea11" .git/refs/heads/main; then
	echo "Got unexpected commit: $(git log --pretty=format:'%h' -n 1)"
	exit 1
fi
cd ../rustc-demangle || exit
# TODO: What should I test here?
cd ../miniz-3.0.1 || exit
if [ ! -f "miniz.c" ]; then
	echo "Missing miniz.c"
	exit 1
fi
if [ ! -f "meson.build" ]; then
	echo "Missing meson.build"
	exit 1
fi
cd ../turtle-1.3.2 || exit
if [ ! -d "doc" ]; then
	echo "Missing directory doc/"
	exit 1
fi
if [ ! -f "meson.build" ]; then
	echo "Missing meson.build"
	exit 1
fi
cd ../sqlite-amalgamation-3080802 || exit
if [ ! -f "meson.build" ]; then
	echo "Missing meson.build"
	exit 1
fi
cd ../pango-1.50.12 || exit
if grep -q "FOOBARBAZ" meson.build; then
	:
else
	echo "Patch wasn't applied"
	exit 1
fi
cd ..
cd ..
rm -rf __wrap_target
echo "No errors"