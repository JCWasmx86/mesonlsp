## Failing projects
A failing project is a project that shows errors. It is assumed that the meson.build files are correct and just the TypeAnalyzer
is wrong.

### GStreamer
A lot of misc errors in the parent project
#### gst-plugins-base
- `need_api_gles` can't be found for an unknown reason.

### Wrapdb
#### GLib
- Unknown error. Probably related to operator precedence
#### lz4
- `compile_args` can't be found for an unknown reason
#### mpdecimal
- `mpd_header_config_32_LEGACY` and `mpd_header_config_UNIVERSAL` can't be found for an unknown reason

### mesa
`inc_egl` and `inc_egl_dri2` are undefined in `src/gallium/frontends/omx/meson.build`. These variables are defined in `src/egl/meson.build`.
In `src/meson.build`, a `subdir('gallium')` call is before the one with `subdir('egl')`, thus leading to an error.
### glib
In `gnulib/gl_cv_func_printf_directive_f/meson.build` around line 63:
```
if host_system in ['linux', 'android']
    gl_cv_func_printf_directive_f = true
# ... checks for other operating systems...
# Split the check from the main if statement, ensure that
# some meson versions (old ones, presumable) won't try
# to evaluate host_system[9] when it's shorter than that
  elif host_system.startswith ('solaris2.')
    if (host_system[9] == '1' and
        '0123456789'.contains (host_system[10])) or
       ('23456789'.contains (host_system[9]) == '1' and # The error is here: Unable to apply operator `equalsEquals` to types bool and str
        '0123456789'.contains (host_system[10]))
      gl_cv_func_printf_directive_f = true
    elif host_system.startswith ('solaris')
      gl_cv_func_printf_directive_f = false
    endif
  elif host_system.startswith ('solaris')
    gl_cv_func_printf_directive_f = false
  elif host_system == 'windows'
```
