str = 'simplestr'
subdir(str)
# ana:var: simplestrvar = int
arr = ['foo', 'bar']
foreach x : arr
    subdir(x)
endforeach
# ana:var: foo = int
# ana:var: bar = int
foreach x : ['foo2', 'bar2']
    subdir(x)
endforeach
# ana:var: foo2 = int
# ana:var: bar2 = int
foreach x : ['b1', 'b2']
    if true
        subdir(x)
    endif
endforeach
# ana:var: b1 = int
# ana:var: b2 = int
asm = 'asm'
if foo
    asm = 'no-asm'
endif
subdir('foo' / asm)
# ana:var: foo_asm = int
# ana:var: foo_no_asm = int

if foo
    asm1 = 'no-asm'
else
    asm1 = 'asm'
endif
subdir('bar' / asm1)
# ana:var: bar_asm = int
# ana:var: bar_no_asm = int

cc_dict = {
    'compiler': meson.get_compiler('c'),
    'machine': host_machine,
    'config_h_subdir': 'hash1/public',
    'native': false,
}
cc_native_dict = {
    'compiler': meson.get_compiler('c', native: true),
    'machine': build_machine,
    'config_h_subdir': 'hash1/private',
    'native': true,
}
configurations = [cc_dict, cc_native_dict]
foreach entry : configurations
    subdir(entry.get('config_h_subdir'))
endforeach
# ana:var: hash1_private = int
# ana:var: hash1_public = int

# From CMocka
cc_dict2 = {
    'compiler': meson.get_compiler('c'),
    'machine': host_machine,
    'config_h_subdir': 'hash2/public',
    'native': false,
}
cc_native_dict2 = {
    'compiler': meson.get_compiler('c', native: true),
    'machine': build_machine,
    'config_h_subdir': 'hash2/private',
    'native': true,
}
configurations2 = [cc_dict2, cc_native_dict2]
foreach entry : configurations2
    subdir(entry['config_h_subdir'])
endforeach
# ana:var: hash2_private = int
# ana:var: hash2_public = int
supported_arch = {
    'x86' : 'x86',
    'x86_64' : 'x86'
}
arch = host_machine.cpu()
subdir(join_paths('arch', supported_arch[arch]))
# ana:var: issue18 = bool
