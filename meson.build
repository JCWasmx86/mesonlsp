project('Swift-MesonLSP', 'swift', 'c', 'cpp')

cc = meson.get_compiler('c')
cxx = meson.get_compiler('cpp')

if cc.get_id() != 'clang' or cxx.get_id() != 'clang'
  error('You must build using clang(++) (CC=clang CXX=clang++ meson setup ...)')
endif

logging_proj = subproject('logging')
logging_dep = logging_proj.get_variable('swift_log_dep')
crypto_proj = subproject('crypto')
crypto_dep = crypto_proj.get_variable('crypto_dep')

subdir('Sources')
