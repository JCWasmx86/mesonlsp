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

vpx_features = [
    [
        'vpx/vp8cx.h',
        'vpx_codec_vp8_cx_algo',
        '-DHAVE_VP8_ENCODER',
        'VP8 encoder',
    ],
    [
        'vpx/vp8dx.h',
        'vpx_codec_vp8_dx_algo',
        '-DHAVE_VP8_DECODER',
        'VP8 decoder',
    ],
    [
        'vpx/vp8cx.h',
        'vpx_codec_vp9_cx_algo',
        '-DHAVE_VP9_ENCODER',
        'VP9 encoder',
    ],
    [
        'vpx/vp8dx.h',
        'vpx_codec_vp9_dx_algo',
        '-DHAVE_VP9_DECODER',
        'VP9 decoder',
    ],
]
foreach f : vpx_features
    set_variable('have_' + f.get(3).to_lower().underscorify(), true)
endforeach
# ana:var: have_vp8_encoder = bool
# ana:var: have_vp8_decoder = bool
# ana:var: have_vp9_encoder = bool
# ana:var: have_vp9_decoder = bool

vpx2_features = [
    [
        'vpx/vp6cx.h',
        'vpx_codec_vp6_cx_algo',
        '-DHAVE_VP6_ENCODER',
        'VP6 encoder',
    ],
    [
        'vpx/vp6dx.h',
        'vpx_codec_vp6_dx_algo',
        '-DHAVE_VP8_DECODER',
        'VP6 decoder',
    ],
    [
        'vpx/vp7cx.h',
        'vpx_codec_vp7_cx_algo',
        '-DHAVE_VP7_ENCODER',
        'VP7 encoder',
    ],
    [
        'vpx/vp7dx.h',
        'vpx_codec_vp7_dx_algo',
        '-DHAVE_VP7_DECODER',
        'VP7 decoder',
    ],
]
foreach f : vpx2_features
    set_variable('have_' + f[3].to_lower().underscorify(), true)
endforeach
# ana:var: have_vp6_encoder = bool
# ana:var: have_vp6_decoder = bool
# ana:var: have_vp7_encoder = bool
# ana:var: have_vp7_decoder = bool

test_apps = [
    [
        'srtp_driver',
        {
            'extra_sources': 'util.c',
            'run_args': '-v',
        },
    ],
    [
        'replay_driver',
        {
            'extra_sources': 'ut_sim.c',
            'run_args': '-v',
        },
    ],
    [
        'roc_driver',
        {
            'extra_sources': 'ut_sim.c',
            'run_args': '-v',
        },
    ],
    [
        'rdbx_driver',
        {
            'extra_sources': 'ut_sim.c',
            'run_args': '-v',
        },
    ],
    ['test_srtp', {'run_args': '-v'}],
    [
        'rtpw',
        {
            'extra_sources': ['rtp.c', 'util.c', '../crypto/math/datatypes.c'],
            'define_test': false,
        },
    ],
]
foreach t : test_apps
    test_name = t.get(0)
    set_variable(test_name + '_exe', true)
endforeach
# ana:var: rtpw_exe = bool

generated_headers = [
    {
        'scanner_args': ['server-header'],
        'output': 'wayland-server-protocol.h',
        'install': true,
    },
    {
        'scanner_args': ['server-header', '-c'],
        'output': 'wayland-server-protocol-core.h',
        'install': false,
    },
    {
        'scanner_args': ['client-header'],
        'output': 'wayland-client-protocol.h',
        'install': true,
    },
    {
        'scanner_args': ['client-header', '-c'],
        'output': 'wayland-client-protocol-core.h',
        'install': false,
    },
]
foreach gen: generated_headers
    output_file = gen.get('output')
    target_name = output_file.underscorify()
    set_variable(target_name, true)
endforeach
## TODO: Disabled
#ana:var: wayland_client_protocol_h = bool
#ana:var: wayland_server_protocol_h = bool
#ana:var: wayland_client_protocol_core_h = bool
#ana:var: wayland_server_protocol_core_h = bool
