# Guide for contributors
- Check [PROGRESS.md] or the issues for tasks you could work on.
- Implement the task
- Submit a Pull Request.

## Code style
- [swift-format](https://github.com/apple/swift-format) is used for formatting. Use
```
swift-format -i --recursive Package.swift Sources/ Tests/
```
before submitting a PR.
- [SwiftLint](https://github.com/realm/Swiftlint) is used for linting. Use
```
swiftlint --progress Sources/ Tests/ Package.swift
```
for linting. No warnings should be shown, otherwise fix them or disable them for the
part of the code, if there are good reasons.

