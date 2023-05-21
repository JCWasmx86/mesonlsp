#!/usr/bin/env bash
# Failing tests:
# common/158 disabler: I don't understand what the behavior of disablers is
# common/162 subdir if_found: Expected failure
# common/187 args flattening: Argument flattening not implemented
# common/223 persubproject options: Subprojects are not implemented
# common/49 custom target: Something weird with disablers
# common/67 modules: Unimplemented test module. Won't be implemented.
# failing/11 object arithmetic: Expected failure
# failing/12 string arithmetic: Expected failure
# failing/13 array arithmetic: Expected failure
# failing/15 kwarg before arg: Expected failure
# failing/18 wrong plusassign: Expected failure
# failing/39 kwarg assign: Expected failure
# failing/3 missing subdir: Expected failure
# failing/49 executable comparison: Expected failure
# failing/4 missing meson.build: Expected failure
# failing/50 inconsistent comparison: Expected failure
# failing/57 assign custom target index: Expected failure
# failing/5 misplaced option: Expected failure
# failing/97 subdir parse error: Expected failure
# frameworks/23 hotdoc: Missing kwargs for the hotdoc module, but I did not find their types
# frameworks/4 qt: Bad search for the missing method, if it couldn't be inferred due to having no string literal as argument
# unit/21 exit status: Expected failure
# unit/25 non-permitted kwargs: Expected failure
swift build -c release --static-swift-stdlib || exit
export LSPPATH=$PWD/.build/release/Swift-MesonLSP
export OUTPUTPATH=$PWD/failures.txt
rm -rf meson "$OUTPUTPATH"
git clone https://github.com/mesonbuild/meson.git || exit
cd "meson/test cases" || exit
git checkout e1de1bae0997f38370bb9cae3f158af9ae3f14ac
for i in *; do
	echo "Entering testdir \"$i\""
	cd "$i" || exit
	for j in *; do
		echo "Testing \"$i//$j\""
		cd "$j" || exit
		output=$($LSPPATH meson.build | grep -v testcase | grep -v expect_error)
		testname="$i/$j"
		# shellcheck disable=SC2235
		if echo "$output" | grep -q "🔴"; then
			if [ "$(echo "$output" | grep -c 🔴)" -eq 1 ] &&
				([ "$testname" == "common/162 subdir if_found" ] ||
					[ "$testname" == "common/67 modules" ] ||
					[ "$testname" == "failing/11 object arithmetic" ] ||
					[ "$testname" == "failing/12 string arithmetic" ] ||
					[ "$testname" == "failing/13 array arithmetic" ] ||
					[ "$testname" == "failing/15 kwarg before arg" ] ||
					[ "$testname" == "failing/18 wrong plusassign" ] ||
					[ "$testname" == "failing/39 kwarg assign" ] ||
					[ "$testname" == "failing/3 missing subdir" ] ||
					[ "$testname" == "failing/49 executable comparison" ] ||
					[ "$testname" == "failing/4 missing meson.build" ] ||
					[ "$testname" == "failing/57 assign custom target index" ] ||
					[ "$testname" == "failing/5 misplaced option" ] ||
					[ "$testname" == "failing/97 subdir parse error" ] ||
					[ "$testname" == "failing/130 invalid ast" ] ||
					[ "$testname" == "failing/131 invalid project function" ] ||
					[ "$testname" == "failing/1 project not first" ] ||
					[ "$testname" == "unit/21 exit status" ]); then
				:
			elif [ "$(echo "$output" | grep -c 🔴)" -eq 2 ] && [ "$testname" == "failing/55 or on new line" ]; then
				:
			elif [ "$(echo "$output" | grep -c 🔴)" -eq 3 ] && ([ "$testname" == "failing/50 inconsistent comparison" ] ||
				[ "$testname" == "unit/25 non-permitted kwargs" ]); then
				:
			else
				echo "$i/$j" >>"$OUTPUTPATH"
				echo "$output" >>"$OUTPUTPATH"
			fi
		fi
		cd .. || exit
	done
	cd .. || exit
done
cd ../..
rm -rf meson
count=$(wc -l failures.txt | cut -d ' ' -f 1)
echo "$count lines"
cat failures.txt
if [ "$(wc -l <failures.txt)" -gt 47 ]; then
	exit 1
fi
exit 0
