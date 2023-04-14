# Integrate with GNOME Builder Nightly
## Prerequisites
- Install `org.gnome.Builder.Devel` from [gnome-nightly](https://wiki.gnome.org/Apps/Nightly).
- Install dependencies:
  - For Fedora 37: `sudo dnf install git vala meson gcc libgee-devel json-glib-devel gtk4-devel gtksourceview5-devel libadwaita-devel libpeas-devel template-glib-devel g++ libsoup3-devel`
## Build/Install
Execute these commands. They download the plugin, compile it and set it up automatically.
```
git clone https://github.com/JCWasmx86/GNOME-Builder-Plugins
cd GNOME-Builder-Plugins
# The other plugins in the repo
# get disabled
meson -Dplugin_clangd=disabled \
      -Dplugin_gitgui=disabled \
      -Dplugin_icon_installer=disabled \
      -Dplugin_scriptdir=disabled \
      -Dplugin_shfmt=disabled \
      -Dplugin_swift_templates=disabled \
      -Dplugin_texlab=disabled \
      _build
cd _build
# Don't do "sudo ninja install"
ninja -j $(nproc) install
```

