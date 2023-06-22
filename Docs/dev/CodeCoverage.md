# Getting code coverage
- Build with `swift build -c release --static-swift-stdlib -Xswiftc -profile-generate -Xswiftc -profile-coverage-mapping`
- Run the program
- `cp default.profraw /somedir`
- `llvm-profdata merge -sparse default.profraw -o default.profdata`
- `llvm-cov export --instr-profile default.profdata ~/Projects/Swift-MesonLSP/.build/release/Swift-MesonLSP -format lcov|swift demangle > out.lcov`
- `genhtml --ignore-errors source out.lcov --legend --output-directory=/tmp/somepath`

