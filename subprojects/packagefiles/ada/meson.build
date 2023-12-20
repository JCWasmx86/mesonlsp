project('ada', 'cpp')

ada_inc = include_directories('include')
ada_lib = library('ada', 'src/ada.cpp', include_directories: ada_inc)
ada_dep = declare_dependency(link_with: ada_lib, include_directories: ada_inc)