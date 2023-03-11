## Failing projects
A failing project is a project that shows errors. It is assumed that the meson.build files are correct and just the TypeAnalyzer
is wrong.

### GStreamer
A lot of misc errors in the parent project
#### gst-plugins-base
- `need_api_gles` can't be found for an unknown reason.
#### gst-plugins-good
- `have_vp8_encoder` and `have_vp9_encoder` can't be found, as the expression that calculates those variable names is too complex.
#### gst-plugins-rs
- `gst_dep` and `gst_dl_dep` can't be found, as the expression that calculates those variable names is too complex.
#### libsrtp
- `rtpw_exe` can't be found, as the expression that calculates those variable names is too complex.

### Wrapdb
#### CMocka
- `inc_private_native` and `inc_private` can't be found, as they are defined in a subdir that is not visited, as the computing expression for `subdir()` is too complex.
#### GLib
- Unknown error. Probably related to operator precedence
#### Harfbuzz
- `hb_shape_fuzzer_exe`, `hb_subset_fuzzer_exe` and `hb_draw_fuzzer_exe` can't be found, as the expression that calculates those variable names is too complex.
#### libsrtp
- `rtpw_exe` can't be found, as the expression that calculates those variable names is too complex.
#### lz4
- `compile_args` can't be found for an unknown reason
#### mpdecimal
- `mpd_header_config_32_LEGACY` and `mpd_header_config_UNIVERSAL` can't be found for an unknown reason
#### OpenSSL
- Various missing variables, as they are defined in a subdir that is not visited, as the computing expression for `subdir()` is too complex.
#### Wayland
- Various missing variables, as the expression that calculates those variable names is too complex.
