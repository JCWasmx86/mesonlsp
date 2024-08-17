# 4.3.3 (Aug 17 2024)
- Make it work in Helix
- Propagate wrap setup errors to the editor (#126)
- Fix bugs in the wrap file parser tree-sitter-ini (#126)
# 4.3.2 (Aug 04 2024)
- Add basic support for f-strings in subproject/subdir/set_variable calls (#114)
- Fix wrong directory being selected for subprojects
- Fix NUL bytes appended to file when formatting on Windows (https://github.com/mesonbuild/vscode-meson/issues/253)
# 4.3.1 (Jul 12 2024)
- Fix crash for empty project/meson.build (#109)
# 4.3.0 (Jun 30 2024)
- Add support for specifying custom `subproject_dir` (top level directory name that holds Meson subprojects) (#88, by @fourdim)
- Fix code formatting duplicating the last line when meson.build has fewer lines (#101)
- Fix malformed entries in completion list (#92)
- Deduplicate completion list (#92)
- Fix missing error, if an unknown variable is used as argument for a kwarg with the same name as the kwarg itself.
- Add missing constants from reference tables (#103, by @blue42u)
- Add partial support for `str.replace()` in the interpreter (Fixes parsing of [Lix](https://git.lix.systems/lix-project/lix))
- Update API compat to 1.5.0rc1
# 4.2.0 (May 03 2024)
- Add `mesonlint` tool that allows to lint a project and to check+fix the formatting. It's currently not integrated with the language server.
- Fix a few deprecation informations (#70, by @ptomato)
- Fix crash if there was an iteration statement without variables
- Add option to emit warnings, if a loop variable has the same name as a enclosing one. (`disableIterationVariableShadowingLint`)
- Add option to emit warnings, if a loop variable is overwritten in the body. (Off by default, `enableIterationVariableLint`)
- Fix types of `default_options`
- Make `mesonlsp` compile on `aarch64-unknown-linux-gnu`
- Don't report warning about format identifiers in string for `vcs_tag::@replace_string@`
- Show errors for nested ternaries, as they are forbidden.
- Add a few new kwargs from meson 1.4.0
# 4.1.8 (Apr 01 2024)
- Minor fix
# 4.1.6 (Apr 01 2024)
- Minor fix
# 4.1.5 (Apr 01 2024)
- Build fix
# 4.1.4 (Apr 01 2024)
- Misc improvements to .spec file and buildsystem
- Minor fixes
# 4.1.3 (Mar 23 2024)
- Add formatting support for windows
# 4.1.1 (Mar 19 2024)
- Adjust artifact names
- New AUR package by @polyzen
# 4.1.0 (Mar 14 2024)
- Reduce memory usage
- Improved error handling.
# 4.0.0 (Mar 13 2024)
- Rewrite in C++
- Rename binary to `mesonlsp`
- Add --version switch (C++ version)
- Drop support for Debian/Ubuntu packages
- Drop support for AUR packages
- Drop support for macos 12
- Add support for inlay hints for positional arguments.
- Improve auto-completion
- Adding/Changing subprojects requires languagserver restart on Windows/macOS. This will be addressed in future releases
- `muon` is now built-in. => `others.muonPath` is obsolete now.
- Add `linting.disableUnusedVariableCheck` that allows disabling checks for unused variables
- Add `linting.disableArgTypeChecking` to disable type checking of argument types.
- Add `others.defaultFormattingConfig` that takes a path to the default muon config file.
- Add `others.removeDefaultTypesInInlayHints` that allows removing clutter from inlay hints.
- Add `others.useCustomParser` to use a custom parser (`true` by default)
- Add `others.disablePosargInlayHints` to disable inlay hints for positional arguments
- Formatting will now respect muon_cfg.ini
- Bug fixes to the unused variable check
- File size decreases
- Major performance improvements
- Less RAM usage
- Various typing improvements
# 3.1.4 (Mar 05 2024)
- Fix binary name (Related to #34)
- Fix `default_options accepts a dictionary` (#48)
- Fix gnome::generate_gir@env
# 3.1.3 (Nov 19 2023)
- Fix race condition (#31)
# 3.1.2 (Nov 19 2023)
- Improve heuristics for `subdir(x)`
- Add first diagnostics for `meson_options.txt`/`meson.options` (#25)
- Add missing `str.splitlines` method information (#30)
- Add missing kwargs
# 3.1.1 (Nov 02 2023)
- Fix regression where changed configuration wasn't applied.
# 3.1.0 (Nov 02 2023)
- Mark variables as used, if they are in a format string
- Improve heuristics for `subdir(x)`
- Add `others.muonPath` option that allows you to set the path to the muon binary that should be used.
- Fix some edge cases on hover.
- Remove webserver due to difficulties integrating it with the updated sourcekit-lsp
- Update sourcekit-lsp. (Basically rewrites the server portion) It is quite possible there are regressions!
- Don't report stats to the server anymore.
- Update meson API definitions to cfec255027ca7c928defcc665a12e91b439c7c3f
- Add support for meson.options files (And prefer them over meson_options.txt)
- Fix formatting for bigger files
# 3.0.22 (Oct 27 2023)
- Test-Release for enhanced release workflow
# 3.0.21 (Oct 27 2023)
- Test-Release for enhanced release workflow
# 3.0.20 (Oct 27 2023)
- Test-Release for enhanced release workflow
# 3.0.19 (Oct 27 2023)
- Test-Release for enhanced release workflow
# 3.0.18 (Oct 27 2023)
- Test-Release for enhanced release workflow
# 3.0.17 (Oct 27 2023)
- Test-Release for enhanced release workflow
# 3.0.16 (Oct 27 2023)
- Test-Release for enhanced release workflow
# 3.0.15 (Oct 27 2023)
- Test-Release for enhanced release workflow
# 3.0.14 (Oct 27 2023)
- Provide universal binaries (x86_64, arm64, by @fwcd, #23)
# 3.0.13 (Oct 25 2023)
- Test-Release for enhanced release workflow
# 3.0.12 (Oct 25 2023)
- Test-Release for enhanced release workflow
# 3.0.11 (Oct 25 2023)
- Test-Release for enhanced release workflow
# 3.0.10 (Oct 25 2023)
- Test-Release for enhanced release workflow
# 3.0.9 (Oct 25 2023)
- Test-Release for enhanced release workflow
# 3.0.8 (Oct 25 2023)
- Test-Release for enhanced release workflow
# 3.0.7 (Oct 25 2023)
- Support folding ranges
- @ferdnyc fixed the COPR versioning (#19)
- Fix bug that caused "Updating subprojects" to be persistent.
- Disable downloads of wraps/subprojects, if `others.neverDownloadAutomatically` is set. This *will* show you errors, for every `subproject('XXX')` call that is only
  available as wrap!
- Deduplicate CompletionItems
- Improve CI
- Wait until the meson source tree is rebuilt, before building completions. This may improve the UX of the auto-completion.
# 3.0.6 (Oct 24 2023)
- Add semantic tokens for functions and methods
- Add `others.disableInlayHints` configuration option for disabling inlay hints (#15)
- Fix major bug with semantic tokens
# 3.0.5 (Oct 23 2023)
- Fix semantic tokens
- Minor improvements to the hover-tooltip
- Differentiate `@`s and the variable between in format-strings
- Other improvements to the semantic tokens
# 3.0.4 (Oct 23 2023)
- Fix accidental regressions with the release process
# 3.0.3 (Oct 23 2023)
- Fix accidental regressions with the release process
# 3.0.2 (Oct 23 2023)
- Fix accidental regressions with the release process
# 3.0.1 (Oct 23 2023)
- Fix upload of Windows binaries
# 3.0.0 (Oct 23 2023)
- Improve formatting support on Windows (Or add it, if it ever worked)
- Improve layout of tooltips of functions/methods. (#13)
- Improve error messages for unknown functions/methods (Related to vscode-meson#159
- Improve meson API coverage (Related to vscode-meson#159)
- Add a few missing compiler/argument/arch ids (Related to vscode-meson#159)
- Don't detect assignments from `declare_dependency` as unused assignments
- Improve heuristics for `subdir(x)` with non-constant values of `x` (#18)
- Add a bit of configuration possibilities, configurable with the `InitializationOptions` and `workspace/didChangeConfiguration`
# 2.4.4 (Sep 31 2023)
- Add partial auto-completion after string literals
- Add diagnostics for `str.format()`
- Improve other aspects of auto-completion
# 2.4.3 (Sep 22 2023)
- Switch to swift-log/swift-tools-support-core fork to fix compilation failures on Fedora 39 and Arch-Linux.
# 2.4.2 (Sep 19 2023)
- Add preliminary Swift 5.9 support
- Minor internal improvements
# 2.4.1 (Sep 12 2023)
- Bump API definitions to mesonbuild/meson#6cfd2b4d5bd30b372268c25308b1cb00afd0996d
- Huge improvements to auto-completion
# 2.4 (Sep 02 2023)
- Emit deprecation warnings based on `meson_version` (#9)
- Add basic file auto-completion
# 2.3.15 (Jul 06 2023)
- Minor fixes
# 2.3.14 (Jul 06 2023)
- Minor fixes
# 2.3.13 (Jul 06 2023)
- Minor fixes
# 2.3.12 (Jul 05 2023)
- Minor fixes
# 2.3.11 (Jul 05 2023)
- Minor fixes
# 2.3.10 (Jul 05 2023)
- Minor fixes
# 2.3.9 (Jul 05 2023)
- Minor fixes
# 2.3.8 (Jul 01 2023)
- Minor fixes
# 2.3.7 (Jul 01 2023)
- Minor fixes
# 2.3.6 (Jul 01 2023)
- Minor fixes
# 2.3.5 (Jul 01 2023)
- Minor fixes
# 2.3.4 (Jul 01 2023)
- Test uploading to swift-mesonlsp-apt-repo
# 2.3.3 (Jul 01 2023)
- Fix typo
# 2.3.2 (Jul 01 2023)
- Remove meson buildsystem introduced in v2.2
- Only enable renaming in GNOME-Builder. It is broken in VSCode and Kate at least. (See #7 and #8)
- Regression fixes for codeactions
(Note this release is only submitted to COPR and available via the Github Actions tab due to testing I need to do)
# 2.3.1 (Jun 18 2023)
- Auto-complete pkg-config package names in `dependency('foo')`
- Add /stats endpoint on Linux. It shows the amount of requests, notifications and the memory usage over the time.
- Only start rebuilding a tree, if it hasn't changed for 100ms. This lowers the CPU load and decreases the growth of the memory usage.
- Misc bug fixes
- Auto-complete option names in `get_option()`
- Show error, if attempting to assign to a reserved variable.
# 2.3 (Jun 10 2023)
- Fix race condition that lead to crashes, especially during initialization
- Show error if variable does not exist in subproject
- Show error if subproject does not exist
- Added the ability to the CLI of the language server to generate a graph of the subdirectory structure.
- Add code action to automatically download wrap from WrapDB
- Renaming support. Please note that this is somewhat experimental and may break. So make backups before attempting to rename variables.
- Do basic typechecking of arguments. It is quite imprecise, but should catch a lot of really wrong types, but it does not differentiate between `list(foo)` and `foo` due to the
unfolding rules.
# 2.2 (May 13 2023)
**Note: All codeactions insert code unformatted**
- Build on macOS 13 in CI
- Upload macOS 13 binaries to releases
- Show error, if there is an assignment statement from void
- Add `/count` endpoint that shows the amount of nodes for each (sub)project. It probably won't have any use for endusers.
- Add `/status` endpoint that shows	if all required	programs were found
- Show error, if there are more than two identifiers in iteration statements.
- Show error for `break`s/`continue`s outside of loops
- Add codeaction for converting integer literals to other bases
- Auto complete subproject variables in `subproject.get_variable()`
- Add code action to switch from `static_library()` etc to `library()`
- Add code action to convert from `shared_library` to `shared_module` and reverse
- Add code action to sort filenames in calls to `executable`, `library` and similar. (Only works, if everything is either a string literal or an identifier)
- Update subprojects on launch
- Add code action for moving to `fs.copyfile()` from `configure_file(copy: true)`. Note the refactored code won't be formatted.
- Add code action to create dependency from library
- Add a very experimental meson build system. Requires a [meson fork](https://github.com/JCWasmx86/meson/tree/swift). Don't rely on it, as the buildsystem may be removed
  without any further notice. It's just a Proof-of-concept.
# 2.1 (Apr 22 2023)
- Show choices for array/combo options on hover
- Build .deb files for Ubuntu 18.04/20.04/22.04 and Debian stable/testing/unstable in CI
- Setup [APT Repo](https://github.com/JCWasmx86/swift-mesonlsp-apt-repo) for these distributions
- Include identifiers in auto-completion
- Send progress of setting up the subprojects to the client ([Includes work upstream](https://github.com/apple/sourcekit-lsp/pull/732))
- Fix crash, if setting up and parsing subprojects was faster than parsing the project itself.
- Show error, if first statement in root meson.build is not a call to `project()`
- Bump COPR to build for Fedora 38.
- Show warnings for duplicate keyword arguments
# 2.0 (Apr 11 2023)
- Only rebuild tree after loading subprojects if a subproject was found
- Rebuild trees of folder based subprojects. This allows e.g. editing while preserving features like hover/document symbols
- Show type documentation on hover, if identifier has only one type
- Enable diagnostic webserver on MacOS
- Add endpoint /caches in built-in webserver to ease debugging (Linux/MacOS-only)
- Print backtrace on signal using swift-backtrace
- Send diagnostics for subprojects to the editor
- Drop swift-atomics dependency
- Detect subprojects that weren't setup fully and reattempt
- Include license and 3rd party libraries in release artifacts
- Show option documentation on hover
- Show warning for duplicate keys in dictionary literals
# 1.6 (Apr 08 2023)
- Don't depend on unzip/tar/xz/bzip2/gunzip for extracting wraps and their patches
- Build binaries for Ubuntu 18.04 and 20.04 in CI
- Measure code coverage in CI
- Cache downloaded wraps (wrap-file only) and downloaded patches
- Setup [AUR package for Archlinux](https://aur.archlinux.org/packages/swift-mesonlsp)
- Implement read-only navigation for subprojects. Formatting won't be supported. Editing the meson code of subprojects that come from .wrap files is undefined behavior and may cause strange issues.
- Use variables from subprojects during type analysis.
# 1.5.1 (Apr 02 2023)
- Use snippets during auto completion
- Setup [COPR](https://copr.fedorainfracloud.org/coprs/jcwasmx86/Swift-MesonLSP/) for Fedora
- Don't show message with memory stats in the editor anymore, as especially in VSCode is was quite annoying.
- Move development from master to main branch
# 1.5 (Mar 28 2023)
- Add dead code detection
- Add detection for code without effect
- Detect unused assignments
- Allow downloading and setting up wraps
- Warn about use of deprecated options
- Add error, if an option does not exist
- Check `compiler.get_id`, `compiler.get_argument_syntax`, `compiler.get_linker_id`, `build_machine.cpu_family` and `build_machine.system` against known values.
- Performance loss between 10% and 20% depending on the project, due to implementing these advanced code analyzers
# 1.4.1 (Mar 20 2023)
- Major code cleanups
- Replaced PathKit dependency by a vendored version.
- Restructured code to allow support for other platforms.
- Add MacOS CI (Provides freshly compiled binaries for testing)
# 1.4 (Mar 17 2023)
- Add support for deriving strings in `subdir(x)`/`set_variable(x)`, where x is not a string literal. The implementation is good enough for parsing WrapDB, GNOME and ElementaryOS correctly.
- Improve dashboard to show more information and work offline
- Minor code cleanups
- Minor performance improvements
- Add regression tests in CI
- Add more projects to benchmark suite
- Update tree-sitter parser
# 1.3 (Mar 11 2023)
- Implement inlay hints
- Implement `textDocument/documentHighlight`
- Listen to `workspace/didCreateFiles` and `workspace/didDeleteFiles`
- Slightly improve auto completion
- Send memory usage information to the server periodically
- Fix a lot of type definitions
- Add some heuristics for `subdir(x)`, where x is not a string literal. This allows parsing e.g. GTK correctly.
- Add web-based dashboard for showing performance over the time
# 1.2.1 (Feb 16 2023)
- Upload binary on release
# 1.2 (Feb 16 2023)
- Cache AST for all unopened documents
- Cancel rebuilding the tree, if another rebuild has started
- Fix some bugs with jumping to declaration. (Sadly comes with a performance regression)
- Add required code for VSCode
- Add installation instructions for Kate
- Don't advertise support for higlighting
- Bump swift-argument-parser
- Setup CI workflow to measure RAM-usage/performance regressions
# 1.1 (Feb 13 2023)
## Changes
- Reduced memory usage (Up to 60%) by just allocating methods for each type only once, instead for each object created.
- Improve performance for some projects (0%-60%) by switching from structs to classes for all types. This reduces the amount of copying needed.
- On the other side, improvements to the type analysis had some negative performance impact. See the measurements below.
- Fix a lot of bad type definitions (Some still remain, feel free to file bugs/submit a PR if you encounter one)
- Implement some test cases for validation of the type deduction and the emitted diagnostics
- Use meson test cases to check for bad type definitions.
- Show an error if the condition is not bool
- Show an error if the number of identifiers in a foreach-loop is not appropriate for the type on the right side
- Several other added diagnostics
- Improve the handling of if-Statements during type deduction
- Fix some bugs regarding the handling of binary expressions during type analysis
- Improve code quality
- Add CI with automatic tests
- Add `--stdio` flag for VSCode. (I have started to work on a [fork of vscode-meson](https://github.com/JCWasmx86/vscode-meson) to add support, but it does not work yet.
Feel free to reach out, if you want to help.)
- If the CLI is used for parsing a project, print the diagnostics in an GCC-compatible style, so it can be used e.g. by IDEs.
- Don't clear file if the meson.build file has parsing errors.
- Bump tree-sitter-meson and fix some parser bugs:
  - Don't fail on empty files with an error
  - Allow uppercase `0X`, `0B`, `0O`

## Measurements
These measurements are based on the meson build system of four projects:
- GNOME Builder (~4.8KLOC meson, medium size)
- GNOME-Builder-Plugins (~465LOC meson, small size)
- mesa (~16.4KLOC, huge size)
- QEMU (~9.3KLOC, medium size)

| Measurement                                                                        | v1.0      | v1.1      | Quotient ((v1.1/v1.0) * 100) - 100 | Better? |
|------------------------------------------------------------------------------------|-----------|-----------|------------------------------------|---------|
| Clean compile time (`rm -rf .build&&swift build -c release --static-swift-stdlib`) | 182.93s   | 211.04s   | +15.4%                             | 🔴      |
| Binary size                                                                        | 86715656B | 86591856B | -0.14%                             | 🟢      |
| Binary size (Stripped)                                                             | 55070672B | 54934992B | -0.24%                             | 🟢      |
| Parsing mesa 10 * 100 times                                                        | 8m33.626s | 8m35.773s | +0.42%                             | 🔴      |
| Parsing QEMU 10 * 100 times                                                        | 8m27.328s | 5m56.167s | -29.80%                            | 🟢      |
| Parsing gnome-builder 10 * 100 times                                               | 3m14.213s | 2m32.249s | -21.61%                            | 🟢      |
| Parsing GNOME-Builder-Plugins 10 * 100 times                                       | 0m39.257s | 0m13.350s | -65.99%                            | 🟢      |
| Allocated during parsing mesa (Sysprof)                                            | 630MB     | 666.8MB   | +5.84%                             | 🔴      |
| Allocated during parsing QEMU (Sysprof)                                            | 622MB     | 514MB     | -17.36%                            | 🟢      |
| Allocated during parsing gnome-builder (Sysprof)                                   | 253.7MB   | 263.3MB   | +3.78%                             | 🔴      |
| Allocated during parsing GNOME-Builder-Plugins (Sysprof)                           | 70.0MB    | 30.2MB    | -56.86%                            | 🟢      |
| Allocations during parsing mesa (Sysprof)                                          | 10393258  | 9482006   | -8.77%                             | 🟢      |
| Allocations during parsing QEMU (Sysprof)                                          | 11976168  | 7512774   | -37.27%                            | 🟢      |
| Allocations during parsing gnome-builder (Sysprof)                                 | 4022854   | 3176052   | -21.05%                            | 🟢      |
| Allocations during parsing GNOME-Builder-Plugins (Sysprof)                         | 1497990   | 348596    | -76.73%                            | 🟢      |
| Peak heap memory usage during parsing mesa (Heaptrack)                             | 165.74M   | 25.93MB   | -84.36%                            | 🟢      |
| Peak heap memory usage during parsing QEMU (Heaptrack)                             | 209.05M   | 25.01M    | -88.03%                            | 🟢      |
| Peak heap memory usage during parsing gnome-builder (Heaptrack)                    | 129.73M   | 11.51M    | -91.12%                            | 🟢      |
| Peak heap memory usage during	parsing	GNOME-Builder-Plugins (Heaptrack)            | 113.93M   | 2.95M     | -97.41%                            | 🟢      |
| Memory usage of language server using mesa and rebuilding tree 70 times            | 493.9MB   | 60.7MB    | -87.71%                            | 🟢      |

`Parsing XYZ 10 * 100 times` was measured like this:
```
echo v1.0
time for i in {0..9}; do
	echo $i
	# Will internally parse the tree 100 times
	# Including converting to an AST and doing
	# typeanalysis/typechecking
	# => 10 * 100 = 1000 iterations
	../v1.0 --path ./meson.build >/dev/null 2>&1
done
echo v1.1
time for i in {0..9}; do
	echo $i
	../v1.1 --path ./meson.build >/dev/null 2>&1
done
```
The number of allocations and the amount of allocations was tracked using Sysprof, just using "Memory Usage" and "Track Allocations" as instruments.
The selected project will be parsed 100 times.

The peak heap memory was obtained by using heaptrack:
```
heaptrack ../v1.0 --path meson.build
heaptrack_print heaptrack.v1.0.somepid.zst | grep peak.heap
heaptrack ../v1.1 --path meson.build
heaptrack_print heaptrack.v1.1.somepid2.zst | grep peak.heap
```
Reference hardware/software:
```
Swift version 5.7.3 (swift-5.7.3-RELEASE)
Target: x86_64-unknown-linux-gnu

Fedora 37
11th Gen Intel i5-1135G7 (8) @ 4.200GHz
```
# 1.0
Initial release
