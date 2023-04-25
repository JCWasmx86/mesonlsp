# Integration with Neovim
**Note**: Neovim is not tested extensively

Add this JSON to `:CocConfig`:
```
{
    "languageserver": {
        "meson": {
            "command": "Swift-MesonLSP",
            "args": ["--lsp"],
            "rootPatterns": ["meson.build"],
            "filetypes": ["meson"]
        }
    }
}
```

