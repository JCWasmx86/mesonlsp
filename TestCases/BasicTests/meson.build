project('foo', 'c')
subdir('nonexisting') # ana:error: nonexisting/meson.build not found
xY = 1 # ana:warn: Expected snake case
x = (
    foo # ana:error: Unknown identifier
)
x = [] # ana:var: x = list()
x.foo() # ana:error: No method foo found for types `list()'
foo() # ana:error: Unknown function foo
dependency() # ana:error: Expected 1 positional arguments, but got none!
sett = ['foo', 1] # ana:var: sett = list(int|str)
set_variable('abc', sett) # ana:var: abc = list(int|str)
xyz = (
    abc # ana:var: xyz = list(int|str)
)
def = get_variable('abc') # ana:var: def = list(int|str)
ghi = get_variable('abc', 1) # ana:var: ghi = list(int|str)|int
dep = dependency('')
if dep.found()
    dep = true
else
    dep = 1
endif
dep1 = (
    dep # ana:var: dep1 = bool|int
)
ternary = (
    true ? 1 : dependency('') # ana:var: ternary = int|dep
)
subdir('subdir1')
unclear = get_variable('have-' + 'foo', '') # ana:var: unclear = any|str
unclear2 = get_variable('foobarbaz__') # ana:var: unclear2 = any
listoflists = [ # ana:var: listoflists = list(list(int|str|dep))
    [1, 1, 1],
    ['', '1', '2'],
    [dependency('')],
]
zzz = 1 # ana:var: zzz = int
zzz += 1
zzz += 'foo' # ana:error: Unable to apply operator `plusequals` to types int and str

