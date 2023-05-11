ccryptoboringsslshims_inc = include_directories('include')
ccryptoboringsslshims_lib = static_library(
    'CCryptoBoringSSLShims',
    'shims.c',
    include_directories: [ccryptoboringsslshims_inc, ccryptoboringssl_inc],
)
ccryptoboringsslshims_dep = declare_dependency(
    link_with: ccryptoboringsslshims_lib,
    include_directories: ccryptoboringsslshims_inc,
)

