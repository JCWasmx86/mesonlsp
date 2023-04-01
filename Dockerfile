FROM fedora:37 AS stage1
WORKDIR /app
RUN dnf install zip swift-lang git libstdc++-static libcurl-devel -y &&\
    dnf clean all &&\
    git clone https://github.com/JCWasmx86/Swift-MesonLSP
WORKDIR /app/Swift-MesonLSP
RUN swift build -c release --static-swift-stdlib &&\
    swift build -c debug --static-swift-stdlib &&\
    mkdir -p /app/exportDir &&\
    cp .build/release/Swift-MesonLSP /app/exportDir &&\
    cp .build/debug/Swift-MesonLSP /app/exportDir/Swift-MesonLSP.debug
WORKDIR /app/exportDir
RUN zip -9 Fedora37.zip Swift-MesonLSP.debug Swift-MesonLSP

FROM scratch AS export-stage
COPY --from=stage1 /app/exportDir/Fedora37.zip .