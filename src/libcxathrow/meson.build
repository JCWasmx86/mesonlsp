src_files = [
    'shared.cpp',
]
is_static = get_option('static_build')

if cxx.get_id() == 'gcc'
    backtrace_dep = cxx.find_library('stdc++_libbacktrace', required: false)
    if not backtrace_dep.found() and cxx.version().version_compare('>=14.0.0')
        backtrace_dep = cxx.find_library('libstdc++exp', required: false)
    endif
    if backtrace_dep.found()
        src_files += 'backtrace_stacktrace.cpp'
    else
        if is_static
            # Should only happen in crappy distributions....
            src_files += 'backtrace_null.cpp'
        else
            src_files += 'backtrace_execinfo.cpp'
        endif
    endif
    if is_static
        src_files += 'handle_linux_static_gcc.cpp'
    else
        src_files += 'handle_linux_gcc.cpp'
    endif
elif cxx.get_id() == 'clang'
    if is_static
        src_files += 'backtrace_null.cpp'
    else
        src_files += 'backtrace_execinfo.cpp'
    endif
    src_files += 'handle_linux_static_clang.cpp'
else
    src_files += ['backtrace_null.cpp', 'handle_null.cpp']
endif

cxathrow_deps = [log_dep]
cxathrow_lib = static_library(
    'cxathrow',
    src_files,
    dependencies: cxathrow_deps,
)
cxathrow_dep = declare_dependency(
    dependencies: cxathrow_deps,
    link_with: [cxathrow_lib],
)
