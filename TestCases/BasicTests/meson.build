dummy_before_project = 1 # ana:error: First statement is not a project() call
project('foo', 'c')
subdir('nonexisting') # ana:error: nonexisting/meson.build not found
xY = 1 # ana:warn: Expected snake case
x = (
    foo # ana:error: Unknown identifier `foo`
)
x = [] # ana:var: x = list()
x.foo() # ana:error: No method `foo` found for types `list()'
foo() # ana:error: Unknown function `foo`
dependency() # ana:error: Expected 1 positional arguments, but got none!
sett = ['foo', 1] # ana:var: sett = list(int|str)
set_variable('abc', sett) # ana:var: abc = list(int|str)
xyz = (
    abc # ana:var: xyz = list(int|str)
)
def = get_variable('abc') # ana:var: def = list(int|str)
ghi = get_variable('abc', 1) # ana:var: ghi = int|list(int|str)
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
    true ? 1 : dependency('') # ana:var: ternary = dep|int
)
subdir('subdir1')
unclear = get_variable('have-' + 'foo', '') # ana:var: unclear = any|dict(any)|list(any)|str
unclear2 = get_variable('foobarbaz__') # ana:var: unclear2 = any|dict(any)|list(any)
listoflists = [ # ana:var: listoflists = list(list(dep|int|str))
    [1, 1, 1],
    ['', '1', '2'],
    [dependency('')],
]
zzz = 1 # ana:var: zzz = int
zzz += 1
zzz += 'foo' # ana:error: Unable to apply operator `plusequals` to types int and str
baz = (
    1 ? '' : true # ana:error: Condition is not bool: int
)
if 1 # ana:error: Condition is not bool: int
elif 2 # ana:error: Condition is not bool: int
endif

foreach iter : {} # ana:error: Iterating over a dict requires two identifiers

endforeach
foreach iter : 1 # ana:error: Expression yields no iterable result

endforeach
foreach iter, iter2 : [] # ana:error: Iterating over a list/range requires one identifier

endforeach
foreach iter, iter2 : 1 # ana:error: Expression yields no iterable result

endforeach
foreach iter, iter2 : range(0, 5) # ana:error: Iterating over a list/range requires one identifier

endforeach
executable() # ana:error: Expected 1 positional arguments, but got none!
executable('foo', native: true, '') # ana:error: Unexpected positional argument after a keyword argument
benchmark('foo', files(''), files('')) # ana:error: Expected 2 positional arguments, but got 3!
benchmark('foo', files(''), abc: true) # ana:error: Unknown key word argument 'abc'!
add_global_arguments('-Wall') # ana:error: Missing required key word argument 'language'!
environment().append() # ana:error: Expected 1 positional arguments, but got none!
environment().append('', separator: ':', '') # ana:error: Unexpected positional argument after a keyword argument
meson.get_compiler('c', 'vala') # ana:error: Expected 1 positional arguments, but got 2!
meson.get_compiler('c', abc: true) # ana:error: Unknown key word argument 'abc'!
#meson.add_devenv(environment()) # ana: error: Missing required key word argument 'method'!
exe = build_target('foo', target_type: 'executable') # ana:var: exe = exe
sl = build_target('foo', target_type: 'shared_library') # ana:var: sl = lib
stl = build_target('foo', target_type: 'static_library') # ana:var: stl = lib
sm = build_target('foo', target_type: 'shared_module') # ana:var: sm = build_tgt
bl = build_target('foo', target_type: 'both_libraries') # ana:var: bl = both_libs
library = build_target('foo', target_type: 'library') # ana:var: library = lib
jar = build_target('foo', target_type: 'jar') # ana:var: jar = jar
imadep = dependency('abc')
if not imadep.found()
    imadep = disabler()
endif
checker = (
    imadep # ana:var: checker = dep|disabler
)
UP_BIN = 0B1 # ana:var: UP_BIN = int
UP_HEX = 0X1 # ana:var: UP_HEX = int
UP_OCT = 0O1 # ana:var: UP_OCT = int

1 # ana:warn: Statement does not have an effect or the result to the call is unused
[] # ana:warn: Statement does not have an effect or the result to the call is unused
files() # ana:warn: Statement does not have an effect or the result to the call is unused
error('foo')
dead_code = 1 # ana:warn: Dead code
unused_assignment = 1 # ana:warn: Unused assignment
unused_assignment2 = 1
unused_assignment3 = unused_assignment2 # ana:warn: Unused assignment
is_good_os = build_machine.system() != 'windows1' # ana:warn: Unknown operating system name
dupdict = {
  'foo': 'bar',
  'bar': 'baz',
  'foo': 'baz', # ana:warn: Duplicate key "foo"
}
build_target('foo', target_type: 'both_libraries', target_type: 'executable') # ana:warn: Duplicate key word argument target_type
empty_var = message('') # ana:error: Can't assign from void
foreach iterp, iterq, iterr : {} # ana:error: Iteration statement expects only one or two identifiers
endforeach

continue # ana:error: continue statements are only allowed inside loops
break # ana:error: break statements are only allowed inside loops

meson = 1 # ana:error: Attempted to re-assign to existing, read-only variable

subproj = subproject('foo') # ana:var: subproj = subproject(foo)

