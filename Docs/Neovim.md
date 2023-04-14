# Integration with Neovim
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

