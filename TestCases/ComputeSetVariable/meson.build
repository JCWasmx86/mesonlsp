funcs = [
    'foo',
    'bar',
    'baz'
]
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
