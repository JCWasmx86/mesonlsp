# Install from source.
Swift is required.

1. Clone the repository
2. Execute `swift build -c release --static-swift-stdlib` to get a nearly static binary.(1)
3. Copy `.build/release/Swift-MesonLSP` to `/usr/local/bin/Swift-MesonLSP`


(1)
```
/usr/local/bin/Swift-MesonLSP 
├── libm.so.6 [default path]
│   ├── libc.so.6 [default path]
│   │   └── ld-linux-x86-64.so.2 [default path]
│   └── ld-linux-x86-64.so.2 [default path]
├── ld-linux-x86-64.so.2 [default path]
├── libc.so.6 [default path]
│   └── ld-linux-x86-64.so.2 [default path]
├── libgcc_s.so.1 [default path]
│   └── libc.so.6 [default path]
│       └── ld-linux-x86-64.so.2 [default path]
└── libstdc++.so.6 [default path]
    ├── libm.so.6 [default path]
    │   ├── libc.so.6 [default path]
    │   │   └── ld-linux-x86-64.so.2 [default path]
    │   └── ld-linux-x86-64.so.2 [default path]
    ├── libgcc_s.so.1 [default path]
    │   └── libc.so.6 [default path]
    │       └── ld-linux-x86-64.so.2 [default path]
    ├── ld-linux-x86-64.so.2 [default path]
    └── libc.so.6 [default path]
        └── ld-linux-x86-64.so.2 [default path]
```

