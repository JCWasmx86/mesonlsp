cryptoboringwrapper_lib = static_library(
    'CryptoBoringWrapper',
    'CryptoKitErrors_boring.swift',
    'AEAD/BoringSSLAEAD.swift',
    dependencies: [ccryptoboringsslshims_dep, ccryptoboringssl_dep],
)
cryptoboringwrapper_dep = declare_dependency(
    link_with: cryptoboringwrapper_lib,
    dependencies: [ccryptoboringsslshims_dep, ccryptoboringssl_dep],
)

