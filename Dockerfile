FROM fedora:37 AS stage1
WORKDIR /app
RUN dnf install zip swift-lang git -y &&\
    dnf clean all &&\
    git clone https://github.com/JCWasmx86/Swift-MesonLSP
WORKDIR /app/Swift-MesonLSP
RUN swift build -c release --static-swift-stdlib &&\
    swift build -c debug --static-swift-stdlib &&\
    cp .build/release/Swift-MesonLSP /app &&\
    cp .build/debug/Swift-MesonLSP /app/Swift-MesonLSP.debug
WORKDIR /app
RUN zip -9 Fedora37.zip Swift-MesonLSP.debug Swift-MesonLSP

FROM scratch AS export-stage
COPY --from=stage1 /app/Fedora37.zip .