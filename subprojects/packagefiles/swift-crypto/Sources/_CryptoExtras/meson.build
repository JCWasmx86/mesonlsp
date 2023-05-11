cryptoextras_lib = static_library(
    '_CryptoExtras',
    'AES/AES_GCM_SIV.swift',
    'AES/Block Function.swift',
    'AES/BoringSSL/AES_GCM_SIV_boring.swift',
    'ChaCha20CTR/BoringSSL/ChaCha20CTR_boring.swift',
    'ChaCha20CTR/ChaCha20CTR.swift',
    'RSA/RSA.swift',
    'RSA/RSA_boring.swift',
    'RSA/RSA_security.swift',
    'Util/BoringSSLHelpers.swift',
    'Util/CryptoKitErrors_boring.swift',
    'Util/DigestType.swift',
    'Util/Error.swift',
    'Util/PEMDocument.swift',
    'Util/RandomBytes.swift',
    dependencies: [
        crypto_dep,
        cryptoboringwrapper_dep,
        ccryptoboringssl_dep,
        ccryptoboringsslshims_dep,
    ],
)
cryptoextras_dep = declare_dependency(
    link_with: cryptoextras_lib,
    dependencies: [
        crypto_dep,
        cryptoboringwrapper_dep,
        ccryptoboringssl_dep,
        ccryptoboringsslshims_dep,
    ],
)

