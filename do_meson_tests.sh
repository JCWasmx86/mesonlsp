#!/usr/bin/env bash
swift build -c release --static-swift-stdlib || exit
export LSPPATH=$PWD/.build/debug/Swift-MesonLSP
export OUTPUTPATH=$PWD/failures.txt
rm -rf meson "$OUTPUTPATH"
git clone https://github.com/mesonbuild/meson.git || exit
cd "meson/test cases" || exit
git checkout 7186279ffaf8b5827d5ba4eedbe9249bc48f82c7
for i in *; do
	echo "Entering testdir \"$i\""
	cd "$i" || exit
	for j in *; do
		echo "Testing \"$i//$j\""
		cd "$j" || exit
		output=$($LSPPATH meson.build)
		if echo "$output" | grep -q "🔴"; then

			echo "$i/$j" >>"$OUTPUTPATH"
			echo "$output" >>"$OUTPUTPATH"
		fi
		cd .. || exit
	done
	cd .. || exit
done
cd ../..
rm -rf meson
count=$(echo failures.txt|wc -l)
echo "$count lines"
if [ "$count" -gt 104 ]; then
    exit 1
fi
exit 0