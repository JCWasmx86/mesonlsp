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
