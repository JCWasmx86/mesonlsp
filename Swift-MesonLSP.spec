%global debug_package %{nil}
%undefine _auto_set_build_flags

Name:           Swift-MesonLSP
Version:        0.0.6
Release:        2.2
Summary:        Meson language server
ExclusiveArch:  x86_64

License:        GPL
Source0:        https://github.com/JCWasmx86/Swift-MesonLSP/archive/refs/tags/v2.2.tar.gz

Requires:       bash
BuildRequires:  swift-lang
BuildRequires:  clang
BuildRequires:  git

%description
A meson language server

%prep
%setup -q -n Swift-MesonLSP-2.2


%build
git clone https://github.com/JCWasmx86/Swift-MesonLSP
cd Swift-MesonLSP
git checkout v2.2
swift build -c release --static-swift-stdlib -Xswiftc -g

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/%{_bindir}
cp Swift-MesonLSP/.build/release/Swift-MesonLSP $RPM_BUILD_ROOT/%{_bindir}

%files
%{_bindir}/Swift-MesonLSP

%changelog
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