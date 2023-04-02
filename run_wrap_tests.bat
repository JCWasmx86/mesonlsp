mkdir __wrap_target
swift build --static-swift-stdlib
.\.build\debug\Swift-MesonLSP.exe --wrap Wraps/rustc-demangle.wrap^
 --wrap Wraps/libswiftdemangle.wrap --wrap Wraps/libswiftdemangle2.wrap^
 --wrap Wraps/miniz.wrap --wrap Wraps/turtle.wrap --wrap Wraps/sqlite.wrap^
 --wrap Wraps/pango.wrap --wrap Wraps/turtle2.wrap --wrap Wraps/turtle3.wrap^
 --wrap-output .\__wrap_target --wrap-package-files .\Wraps\packagefiles || exit