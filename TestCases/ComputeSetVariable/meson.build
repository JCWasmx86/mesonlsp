funcs = ['foo', 'bar', 'baz']
foreach x : funcs
    set_variable('have_' + x, true)
endforeach
# ana:var: have_foo = bool
# ana:var: have_bar = bool
# ana:var: have_baz = bool

foreach x : funcs
    set_variable(x + 'have_', true)
endforeach
# ana:var: foohave_ = bool
# ana:var: barhave_ = bool
# ana:var: bazhave_ = bool

foreach x : ['1']
    set_variable('have_' + x, true)
endforeach
# ana:var: have_1 = bool

foreach x : ['2', '3']
    set_variable('have_@0@'.format(x), true)
endforeach
# ana:var: have_2 = bool
# ana:var: have_3 = bool

python_tools = [
    'glib-genmarshal',
    'glib-mkenums',
]
foreach tool : python_tools
    set_variable(tool.underscorify(), true)
endforeach
# ana:var: glib_genmarshal = bool
# ana:var: glib_mkenums = bool

tests = [
    'hb-shape-fuzzer.cc',
    'hb-subset-fuzzer.cc',
    'hb-set-fuzzer.cc',
    'hb-draw-fuzzer.cc',
]
if get_option('experimental_api')
    tests += 'hb-repacker-fuzzer.cc'
endif
foreach file_name : tests
    test_name = file_name.split('.')[0]
    set_variable('@0@_exe'.format(test_name.underscorify()), true)
endforeach
# ana:var: hb_shape_fuzzer_exe = bool
# ana:var: hb_subset_fuzzer_exe = bool
# ana:var: hb_set_fuzzer_exe = bool
# ana:var: hb_draw_fuzzer_exe = bool
# ana:var: hb_repacker_fuzzer_exe = bool

gdkpixbuf_bin = [
    ['gdk-pixbuf-csource'],
    ['gdk-pixbuf-pixdata'],
    ['gdk-pixbuf-query-loaders', ['queryloaders.c']],
]
foreach bin : gdkpixbuf_bin
    bin_name = bin[0]
    set_variable(bin_name.underscorify(), true)
endforeach
# ana:var: gdk_pixbuf_csource = bool
# ana:var: gdk_pixbuf_pixdata = bool
# ana:var: gdk_pixbuf_query_loaders = bool

