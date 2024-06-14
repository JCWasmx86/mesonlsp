catch2_proj = subproject('catch2')
catch2_with_main_dep = catch2_proj.get_variable('catch2_with_main_dep')

executable(
    'tests',
    'add_test.cpp',
    dependencies: [catch2_with_main_dep],
)
