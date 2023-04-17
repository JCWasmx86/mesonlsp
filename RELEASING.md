# Release process
1. Run benchmarks locally
2. Commit benchmarks (And eventually remove HEAD.json)
3. Update RPM spec
4. Update version in .debian/DEBIAN/control
5. Finalize changelog
6. Attach 3rd-party license bundle to released zip files
7. Start new build on [COPR](https://copr.fedorainfracloud.org/coprs/jcwasmx86/Swift-MesonLSP/)
8. Bump [AUR](https://aur.archlinux.org/packages/swift-mesonlsp)
9. Update [apt repo](https://github.com/JCWasmx86/swift-mesonlsp-apt-repo)

# Postrelease
1. Add empty section to changelog

