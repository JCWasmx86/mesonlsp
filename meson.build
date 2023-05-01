project('Swift-MesonLSP', 'swift', 'c', 'cpp')

cc = meson.get_compiler('c')
cxx = meson.get_compiler('cpp')

if cc.get_id() != 'clang' or cxx.get_id() != 'clang'
    error(
        'You must build using clang(++) (CC=clang CXX=clang++ meson setup ...)',
    )
endif

result = run_command('ulimit', '-n', capture: true, check: true)
if result.returncode() != 0
    error('ulimit -n failed')
endif

max_open_fds = result.stdout().to_int()
if max_open_fds < 65536
    error(
        'The maximum number of open file descriptors is too low. (Expected 65536, got @0@) Run `ulimit -n 65536` to raise the limit'.format(
            max_open_fds,
        ),
    )
endif

logging_proj = subproject('logging')
logging_dep = logging_proj.get_variable('swift_log_dep')
crypto_proj = subproject('crypto')
crypto_dep = crypto_proj.get_variable('crypto_dep')

subdir('Sources')
