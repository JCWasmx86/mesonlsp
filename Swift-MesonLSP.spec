%global debug_package %{nil}
%undefine _auto_set_build_flags

Name:           Swift-MesonLSP
Version:        0.0.27
Release:        2.4.4
Summary:        Meson language server
ExclusiveArch:  x86_64

License:        GPL
Source0:        https://github.com/JCWasmx86/Swift-MesonLSP/archive/refs/tags/v2.4.4.tar.gz

Requires:       bash
BuildRequires:  swift-lang
BuildRequires:  clang
BuildRequires:  git

%description
A meson language server

%prep
%setup -q -n Swift-MesonLSP-2.4.4


%build
git clone https://github.com/JCWasmx86/Swift-MesonLSP
cd Swift-MesonLSP
git checkout v2.4.4
swift build -c release --static-swift-stdlib -Xswiftc -g

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/%{_bindir}
cp Swift-MesonLSP/.build/release/Swift-MesonLSP $RPM_BUILD_ROOT/%{_bindir}

%files
%{_bindir}/Swift-MesonLSP

%changelog
* Sun Sep 31 2023 JCWasmx86 <JCWasmx86@t-online.de> - 0.0.27
- Bump to v2.4.4
* Fri Sep 22 2023 JCWasmx86 <JCWasmx86@t-online.de> - 0.0.26
- Bump to v2.4.3
* Wed Sep 20 2023 JCWasmx86 <JCWasmx86@t-online.de> - 0.0.25
- Bump to v2.4.2
* Tue Sep 11 2023 JCWasmx86 <JCWasmx86@t-online.de> - 0.0.24
- Bump to v2.4.1
* Sat Sep 02 2023 JCWasmx86 <JCWasmx86@t-online.de> - 0.0.23
- Bump to v2.4
* Thu Jul 06 2023 JCWasmx86 <JCWasmx86@t-online.de> - 0.0.22
- Bump to v2.3.15
* Thu Jul 06 2023 JCWasmx86 <JCWasmx86@t-online.de> - 0.0.21
- Bump to v2.3.14
* Thu Jul 06 2023 JCWasmx86 <JCWasmx86@t-online.de> - 0.0.20
- Bump to v2.3.13
* Wed Jul 05 2023 JCWasmx86 <JCWasmx86@t-online.de> - 0.0.19
- Bump to v2.3.12
* Wed Jul 05 2023 JCWasmx86 <JCWasmx86@t-online.de> - 0.0.18
- Bump to v2.3.11
* Wed Jul 05 2023 JCWasmx86 <JCWasmx86@t-online.de> - 0.0.17
- Bump to v2.3.10
* Wed Jul 05 2023 JCWasmx86 <JCWasmx86@t-online.de> - 0.0.16
- Bump to v2.3.9
* Sun Jul 01 2023 JCWasmx86 <JCWasmx86@t-online.de> - 0.0.15
- Bump to v2.3.8
* Sun Jul 01 2023 JCWasmx86 <JCWasmx86@t-online.de> - 0.0.14
- Bump to v2.3.7
* Sun Jul 01 2023 JCWasmx86 <JCWasmx86@t-online.de> - 0.0.13
- Bump to v2.3.6
* Sun Jul 01 2023 JCWasmx86 <JCWasmx86@t-online.de> - 0.0.12
- Bump to v2.3.5
* Sun Jul 01 2023 JCWasmx86 <JCWasmx86@t-online.de> - 0.0.11
- Bump to v2.3.4
* Sun Jul 01 2023 JCWasmx86 <JCWasmx86@t-online.de> - 0.0.10
- Bump to v2.3.3
* Sun Jul 01 2023 JCWasmx86 <JCWasmx86@t-online.de> - 0.0.9
- Bump to v2.3.2
* Thu Jun 16 2023 JCWasmx86 <JCWasmx86@t-online.de> - 0.0.8
- Bump to v2.3.1
* Thu Jun 8 2023 JCWasmx86 <JCWasmx86@t-online.de> - 0.0.7
- Bump to v2.3
* Sat May 13 2023 JCWasmx86 <JCWasmx86@t-online.de> - 0.0.6
- Bump to v2.2
* Sat Apr 21 2023 JCWasmx86 <JCWasmx86@t-online.de> - 0.0.5
- Bump to v2.1
* Sun Apr 2 2023 JCWasmx86 <JCWasmx86@t-online.de> - 0.0.4
- Bump to v2.0
* Sun Apr 2 2023 JCWasmx86 <JCWasmx86@t-online.de> - 0.0.3
- Bump to v1.6
* Sun Apr 2 2023 JCWasmx86 <JCWasmx86@t-online.de> - 0.0.2
- Bump to v1.5.1
* Sat Apr 1 2023 JCWasmx86 <JCWasmx86@t-online.de> - 0.0.1
- First version being packaged
