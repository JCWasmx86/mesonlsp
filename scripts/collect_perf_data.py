#!/usr/bin/env python3
# pylint: disable=missing-module-docstring,missing-function-docstring,bare-except,line-too-long
import argparse
import datetime
import json
import logging
import os
import subprocess
import time
import uuid
from functools import reduce

PROJECTS = {
    "gnome-builder": "https://github.com/GNOME/gnome-builder",
    "GNOME-Builder-Plugins": "https://github.com/JCWasmx86/GNOME-Builder-Plugins",
    "gtk": "https://github.com/GNOME/gtk",
    "mesa": "https://gitlab.freedesktop.org/mesa/mesa/",
    "postgres": "https://github.com/postgres/postgres",
    "qemu": "https://github.com/qemu/qemu",
}

MISC_PROJECTS = {
    "bsdutils": "https://github.com/dcantrell/bsdutils",
    "bubblewrap": "https://github.com/containers/bubblewrap",
    "budgie-desktop": "https://github.com/BuddiesOfBudgie/budgie-desktop",
    "bzip2": "https://gitlab.com/federicomenaquintero/bzip2",
    "cglm": "https://github.com/recp/cglm",
    "cinnamon-desktop": "https://github.com/linuxmint/cinnamon-desktop",
    "code": "https://github.com/elementary/code",
    "dbus-broker": "https://github.com/bus1/dbus-broker",
    "dxvk": "https://github.com/doitsujin/dxvk",
    "evince": "https://github.com/GNOME/evince",
    "frida-core": "https://github.com/frida/frida-core",
    "fwupd": "https://github.com/fwupd/fwupd",
    "gitg": "https://github.com/GNOME/gitg",
    "gjs": "https://github.com/GNOME/gjs",
    "glib": "https://github.com/GNOME/glib",
    "gnome-shell": "https://github.com/GNOME/gnome-shell",
    "hexchat": "https://github.com/hexchat/hexchat",
    "igt-gpu-tools": "https://gitlab.freedesktop.org/drm/igt-gpu-tools",
    "knot-resolver": "https://gitlab.nic.cz/knot/knot-resolver",
    "le": "https://github.com/kirushyk/le",
    "libswiftdemangle": "https://github.com/JCWasmx86/libswiftdemangle",
    "libvips": "https://github.com/libvips/libvips",
    "libvirt": "https://gitlab.com/libvirt/libvirt",
    "lxc": "https://github.com/lxc/lxc",
    "miniz": "https://github.com/richgel999/miniz",
    "mpv": "https://github.com/mpv-player/mpv",
    "pipewire": "https://github.com/PipeWire/pipewire",
    "rustc-demangle": "https://github.com/JCWasmx86/rustc-demangle",
    "scipy": "https://github.com/scipy/scipy",
    "systemd": "https://github.com/systemd/systemd",
    "vte": "https://github.com/GNOME/vte",
    "xts": "https://gitlab.freedesktop.org/xorg/test/xts",
    "zrythm": "https://git.sr.ht/%7Ealextee/zrythm",
}

ELEMENTARY_PROJECTS = {
    "appcenter": "https://github.com/elementary/appcenter.git",
    "applications-menu": "https://github.com/elementary/applications-menu.git",
    "appstream-data": "https://github.com/elementary/appstream-data.git",
    "browser": "https://github.com/elementary/browser.git",
    "calculator": "https://github.com/elementary/calculator.git",
    "calendar": "https://github.com/elementary/calendar.git",
    "camera": "https://github.com/elementary/camera.git",
    "capnet-assist": "https://github.com/elementary/capnet-assist.git",
    "cerbere": "https://github.com/elementary/cerbere.git",
    "code": "https://github.com/elementary/code.git",
    "contractor": "https://github.com/elementary/contractor.git",
    "default-settings": "https://github.com/elementary/default-settings.git",
    "desktop": "https://github.com/elementary/desktop.git",
    "dock": "https://github.com/elementary/dock.git",
    "dpms-helper": "https://github.com/elementary/dpms-helper.git",
    "evince": "https://github.com/elementary/evince.git",
    "feedback": "https://github.com/elementary/feedback.git",
    "fileroller": "https://github.com/elementary/fileroller.git",
    "files": "https://github.com/elementary/files.git",
    "flatpak-authenticator": "https://github.com/elementary/flatpak-authenticator.git",
    "flatpak-platform": "https://github.com/elementary/flatpak-platform.git",
    "friends": "https://github.com/elementary/friends.git",
    "gala": "https://github.com/elementary/gala.git",
    "granite": "https://github.com/elementary/granite.git",
    "greeter": "https://github.com/elementary/greeter.git",
    "iconbrowser": "https://github.com/elementary/iconbrowser.git",
    "icons": "https://github.com/elementary/icons.git",
    "initial-setup": "https://github.com/elementary/initial-setup.git",
    "installer": "https://github.com/elementary/installer.git",
    "keyboard": "https://github.com/elementary/keyboard.git",
    "libpantheon-networking": "https://github.com/elementary/libpantheon-networking.git",
    "mail": "https://github.com/elementary/mail.git",
    "music": "https://github.com/elementary/music.git",
    "notifications": "https://github.com/elementary/notifications.git",
    "onboarding": "https://github.com/elementary/onboarding.git",
    "pantheon-agent-geoclue2": "https://github.com/elementary/pantheon-agent-geoclue2.git",
    "pantheon-agent-polkit": "https://github.com/elementary/pantheon-agent-polkit.git",
    "photos": "https://github.com/elementary/photos.git",
    "portals": "https://github.com/elementary/portals.git",
    "print": "https://github.com/elementary/print.git",
    "quick-settings": "https://github.com/elementary/quick-settings.git",
    "screenshot": "https://github.com/elementary/screenshot.git",
    "session-settings": "https://github.com/elementary/session-settings.git",
    "settings-daemon": "https://github.com/elementary/settings-daemon.git",
    "shortcut-overlay": "https://github.com/elementary/shortcut-overlay.git",
    "sideload": "https://github.com/elementary/sideload.git",
    "sound-theme": "https://github.com/elementary/sound-theme.git",
    "stylesheet": "https://github.com/elementary/stylesheet.git",
    "switchboard": "https://github.com/elementary/switchboard.git",
    "switchboard-plug-a11y": "https://github.com/elementary/switchboard-plug-a11y.git",
    "switchboard-plug-about": "https://github.com/elementary/switchboard-plug-about.git",
    "switchboard-plug-applications": "https://github.com/elementary/switchboard-plug-applications.git",
    "switchboard-plug-bluetooth": "https://github.com/elementary/switchboard-plug-bluetooth.git",
    "switchboard-plug-datetime": "https://github.com/elementary/switchboard-plug-datetime.git",
    "switchboard-plug-display": "https://github.com/elementary/switchboard-plug-display.git",
    "switchboard-plug-keyboard": "https://github.com/elementary/switchboard-plug-keyboard.git",
    "switchboard-plug-locale": "https://github.com/elementary/switchboard-plug-locale.git",
    "switchboard-plug-mouse-touchpad": "https://github.com/elementary/switchboard-plug-mouse-touchpad.git",
    "switchboard-plug-network": "https://github.com/elementary/switchboard-plug-network.git",
    "switchboard-plug-notifications": "https://github.com/elementary/switchboard-plug-notifications.git",
    "switchboard-plug-onlineaccounts": "https://github.com/elementary/switchboard-plug-onlineaccounts.git",
    "switchboard-plug-pantheon-shell": "https://github.com/elementary/switchboard-plug-pantheon-shell.git",
    "switchboard-plug-parental-controls": "https://github.com/elementary/switchboard-plug-parental-controls.git",
    "switchboard-plug-power": "https://github.com/elementary/switchboard-plug-power.git",
    "switchboard-plug-printers": "https://github.com/elementary/switchboard-plug-printers.git",
    "switchboard-plug-security-privacy": "https://github.com/elementary/switchboard-plug-security-privacy.git",
    "switchboard-plug-sharing": "https://github.com/elementary/switchboard-plug-sharing.git",
    "switchboard-plug-sound": "https://github.com/elementary/switchboard-plug-sound.git",
    "switchboard-plug-useraccounts": "https://github.com/elementary/switchboard-plug-useraccounts.git",
    "switchboard-plug-wacom": "https://github.com/elementary/switchboard-plug-wacom.git",
    "switchboard-plug-wallet": "https://github.com/elementary/switchboard-plug-wallet.git",
    "tasks": "https://github.com/elementary/tasks.git",
    "terminal": "https://github.com/elementary/terminal.git",
    "videos": "https://github.com/elementary/videos.git",
    "wallpapers": "https://github.com/elementary/wallpapers.git",
    "wingpanel": "https://github.com/elementary/wingpanel.git",
    "wingpanel-indicator-a11y": "https://github.com/elementary/wingpanel-indicator-a11y.git",
    "wingpanel-indicator-bluetooth": "https://github.com/elementary/wingpanel-indicator-bluetooth.git",
    "wingpanel-indicator-datetime": "https://github.com/elementary/wingpanel-indicator-datetime.git",
    "wingpanel-indicator-keyboard": "https://github.com/elementary/wingpanel-indicator-keyboard.git",
    "wingpanel-indicator-network": "https://github.com/elementary/wingpanel-indicator-network.git",
    "wingpanel-indicator-nightlight": "https://github.com/elementary/wingpanel-indicator-nightlight.git",
    "wingpanel-indicator-notifications": "https://github.com/elementary/wingpanel-indicator-notifications.git",
    "wingpanel-indicator-power": "https://github.com/elementary/wingpanel-indicator-power.git",
    "wingpanel-indicator-privacy": "https://github.com/elementary/wingpanel-indicator-privacy.git",
    "wingpanel-indicator-session": "https://github.com/elementary/wingpanel-indicator-session.git",
    "wingpanel-indicator-sound": "https://github.com/elementary/wingpanel-indicator-sound.git",
}

GNOME_PROJECTS = {
    "aisleriot": "https://github.com/GNOME/aisleriot.git",
    "almanah": "https://github.com/GNOME/almanah.git",
    "atk": "https://github.com/GNOME/atk.git",
    "atkmm": "https://github.com/GNOME/atkmm.git",
    "atomix": "https://github.com/GNOME/atomix.git",
    "at-spi2-atk": "https://github.com/GNOME/at-spi2-atk.git",
    "at-spi2-core": "https://github.com/GNOME/at-spi2-core.git",
    "babl": "https://github.com/GNOME/babl.git",
    "balsa": "https://github.com/GNOME/balsa.git",
    "baobab": "https://github.com/GNOME/baobab.git",
    "buoh": "https://github.com/GNOME/buoh.git",
    "calls": "https://github.com/GNOME/calls.git",
    "cantarell-fonts": "https://github.com/GNOME/cantarell-fonts.git",
    "cheese": "https://github.com/GNOME/cheese.git",
    "connections": "https://github.com/GNOME/connections.git",
    "console": "https://github.com/GNOME/console.git",
    "dconf": "https://github.com/GNOME/dconf.git",
    "dconf-editor": "https://github.com/GNOME/dconf-editor.git",
    "devhelp": "https://github.com/GNOME/devhelp.git",
    "d-feet": "https://github.com/GNOME/d-feet.git",
    "dia": "https://github.com/GNOME/dia.git",
    "d-spy": "https://github.com/GNOME/d-spy.git",
    "eog": "https://github.com/GNOME/eog.git",
    "eog-plugins": "https://github.com/GNOME/eog-plugins.git",
    "epiphany": "https://github.com/GNOME/epiphany.git",
    "evince": "https://github.com/GNOME/evince.git",
    "file-roller": "https://github.com/GNOME/file-roller.git",
    "five-or-more": "https://github.com/GNOME/five-or-more.git",
    "folks": "https://github.com/GNOME/folks.git",
    "four-in-a-row": "https://github.com/GNOME/four-in-a-row.git",
    "fractal": "https://github.com/GNOME/fractal.git",
    "frogr": "https://github.com/GNOME/frogr.git",
    "gcab": "https://github.com/GNOME/gcab.git",
    "gcr": "https://github.com/GNOME/gcr.git",
    "gdk-pixbuf": "https://github.com/GNOME/gdk-pixbuf.git",
    "gdm": "https://github.com/GNOME/gdm.git",
    "geary": "https://github.com/GNOME/geary.git",
    "gedit": "https://github.com/GNOME/gedit.git",
    "gedit-latex": "https://github.com/GNOME/gedit-latex.git",
    "gedit-plugins": "https://github.com/GNOME/gedit-plugins.git",
    "gegl": "https://github.com/GNOME/gegl.git",
    "geocode-glib": "https://github.com/GNOME/geocode-glib.git",
    "gexiv2": "https://github.com/GNOME/gexiv2.git",
    "ghex": "https://github.com/GNOME/ghex.git",
    "gi-docgen": "https://github.com/GNOME/gi-docgen.git",
    "gimp": "https://github.com/GNOME/gimp.git",
    "gitg": "https://github.com/GNOME/gitg.git",
    "gjs": "https://github.com/GNOME/gjs.git",
    "glade": "https://github.com/GNOME/glade.git",
    "glib": "https://github.com/GNOME/glib.git",
    "glibmm": "https://github.com/GNOME/glibmm.git",
    "glib-networking": "https://github.com/GNOME/glib-networking.git",
    "gnome-2048": "https://github.com/GNOME/gnome-2048.git",
    "gnome-autoar": "https://github.com/GNOME/gnome-autoar.git",
    "gnome-backgrounds": "https://github.com/GNOME/gnome-backgrounds.git",
    "gnome-bluetooth": "https://github.com/GNOME/gnome-bluetooth.git",
    "gnome-boxes": "https://github.com/GNOME/gnome-boxes.git",
    "gnome-break-timer": "https://github.com/GNOME/gnome-break-timer.git",
    "gnome-browser-connector": "https://github.com/GNOME/gnome-browser-connector.git",
    "gnome-browser-extension": "https://github.com/GNOME/gnome-browser-extension.git",
    "gnome-builder": "https://github.com/GNOME/gnome-builder.git",
    "gnome-calculator": "https://github.com/GNOME/gnome-calculator.git",
    "gnome-calendar": "https://github.com/GNOME/gnome-calendar.git",
    "gnome-characters": "https://github.com/GNOME/gnome-characters.git",
    "gnome-chess": "https://github.com/GNOME/gnome-chess.git",
    "gnome-clocks": "https://github.com/GNOME/gnome-clocks.git",
    "gnome-color-manager": "https://github.com/GNOME/gnome-color-manager.git",
    "gnome-commander": "https://github.com/GNOME/gnome-commander.git",
    "gnome-contacts": "https://github.com/GNOME/gnome-contacts.git",
    "gnome-control-center": "https://github.com/GNOME/gnome-control-center.git",
    "gnome-desktop": "https://github.com/GNOME/gnome-desktop.git",
    "gnome-desktop-testing": "https://github.com/GNOME/gnome-desktop-testing.git",
    "gnome-disk-utility": "https://github.com/GNOME/gnome-disk-utility.git",
    "gnome-epub-thumbnailer": "https://github.com/GNOME/gnome-epub-thumbnailer.git",
    "gnome-font-viewer": "https://github.com/GNOME/gnome-font-viewer.git",
    "gnome-initial-setup": "https://github.com/GNOME/gnome-initial-setup.git",
    "gnome-kiosk": "https://github.com/GNOME/gnome-kiosk.git",
    "gnome-klotski": "https://github.com/GNOME/gnome-klotski.git",
    "gnome-logs": "https://github.com/GNOME/gnome-logs.git",
    "gnome-mahjongg": "https://github.com/GNOME/gnome-mahjongg.git",
    "gnome-maps": "https://github.com/GNOME/gnome-maps.git",
    "gnome-mines": "https://github.com/GNOME/gnome-mines.git",
    "gnomemm-website": "https://github.com/GNOME/gnomemm-website.git",
    "gnome-mud": "https://github.com/GNOME/gnome-mud.git",
    "gnome-multi-writer": "https://github.com/GNOME/gnome-multi-writer.git",
    "gnome-music": "https://github.com/GNOME/gnome-music.git",
    "gnome-nettool": "https://github.com/GNOME/gnome-nettool.git",
    "gnome-network-displays": "https://github.com/GNOME/gnome-network-displays.git",
    "gnome-nibbles": "https://github.com/GNOME/gnome-nibbles.git",
    "gnome-notes": "https://github.com/GNOME/gnome-notes.git",
    "gnome-online-accounts": "https://github.com/GNOME/gnome-online-accounts.git",
    "gnome-packagekit": "https://github.com/GNOME/gnome-packagekit.git",
    "gnome-photos": "https://github.com/GNOME/gnome-photos.git",
    "gnome-power-manager": "https://github.com/GNOME/gnome-power-manager.git",
    "gnome-remote-desktop": "https://github.com/GNOME/gnome-remote-desktop.git",
    "gnome-robots": "https://github.com/GNOME/gnome-robots.git",
    "gnome-screenshot": "https://github.com/GNOME/gnome-screenshot.git",
    "gnome-session": "https://github.com/GNOME/gnome-session.git",
    "gnome-settings-daemon": "https://github.com/GNOME/gnome-settings-daemon.git",
    "gnome-shell": "https://github.com/GNOME/gnome-shell.git",
    "gnome-shell-extensions": "https://github.com/GNOME/gnome-shell-extensions.git",
    "gnome-software": "https://github.com/GNOME/gnome-software.git",
    "gnome-sound-recorder": "https://github.com/GNOME/gnome-sound-recorder.git",
    "gnome-subtitles": "https://github.com/GNOME/gnome-subtitles.git",
    "gnome-sudoku": "https://github.com/GNOME/gnome-sudoku.git",
    "gnome-system-monitor": "https://github.com/GNOME/gnome-system-monitor.git",
    "gnome-taquin": "https://github.com/GNOME/gnome-taquin.git",
    "gnome-terminal": "https://github.com/GNOME/gnome-terminal.git",
    "gnome-tetravex": "https://github.com/GNOME/gnome-tetravex.git",
    "gnome-text-editor": "https://github.com/GNOME/gnome-text-editor.git",
    "gnome-tour": "https://github.com/GNOME/gnome-tour.git",
    "gnome-tweaks": "https://github.com/GNOME/gnome-tweaks.git",
    "gnome-usage": "https://github.com/GNOME/gnome-usage.git",
    "gnome-user-share": "https://github.com/GNOME/gnome-user-share.git",
    "gnome-video-effects": "https://github.com/GNOME/gnome-video-effects.git",
    "gnome-weather": "https://github.com/GNOME/gnome-weather.git",
    "gnote": "https://github.com/GNOME/gnote.git",
    "gobject-introspection": "https://github.com/GNOME/gobject-introspection.git",
    "gom": "https://github.com/GNOME/gom.git",
    "goobox": "https://github.com/GNOME/goobox.git",
    "grilo": "https://github.com/GNOME/grilo.git",
    "grilo-mediaserver2": "https://github.com/GNOME/grilo-mediaserver2.git",
    "grilo-plugins": "https://github.com/GNOME/grilo-plugins.git",
    "gsettings-desktop-schemas": "https://github.com/GNOME/gsettings-desktop-schemas.git",
    "gsound": "https://github.com/GNOME/gsound.git",
    "gssdp": "https://github.com/GNOME/gssdp.git",
    "gst-debugger": "https://github.com/GNOME/gst-debugger.git",
    "gthumb": "https://github.com/GNOME/gthumb.git",
    "gtk": "https://github.com/GNOME/gtk.git",
    "gtk-doc": "https://github.com/GNOME/gtk-doc.git",
    "gtk-frdp": "https://github.com/GNOME/gtk-frdp.git",
    "gtkmm": "https://github.com/GNOME/gtkmm.git",
    "gtkmm-documentation": "https://github.com/GNOME/gtkmm-documentation.git",
    "gtksourceview": "https://github.com/GNOME/gtksourceview.git",
    "gtranslator": "https://github.com/GNOME/gtranslator.git",
    "gucharmap": "https://github.com/GNOME/gucharmap.git",
    "gupnp": "https://github.com/GNOME/gupnp.git",
    "gupnp-av": "https://github.com/GNOME/gupnp-av.git",
    "gupnp-dlna": "https://github.com/GNOME/gupnp-dlna.git",
    "gupnp-igd": "https://github.com/GNOME/gupnp-igd.git",
    "gupnp-tools": "https://github.com/GNOME/gupnp-tools.git",
    "gvdb": "https://github.com/GNOME/gvdb.git",
    "gvfs": "https://github.com/GNOME/gvfs.git",
    "gxml": "https://github.com/GNOME/gxml.git",
    "hitori": "https://github.com/GNOME/hitori.git",
    "iagno": "https://github.com/GNOME/iagno.git",
    "json-glib": "https://github.com/GNOME/json-glib.git",
    "jsonrpc-glib": "https://github.com/GNOME/jsonrpc-glib.git",
    "krb5-auth-dialog": "https://github.com/GNOME/krb5-auth-dialog.git",
    "libadwaita": "https://github.com/GNOME/libadwaita.git",
    "libchamplain": "https://github.com/GNOME/libchamplain.git",
    "libdazzle": "https://github.com/GNOME/libdazzle.git",
    "libdex": "https://github.com/GNOME/libdex.git",
    "libgd": "https://github.com/GNOME/libgd.git",
    "libgda": "https://github.com/GNOME/libgda.git",
    "libgdata": "https://github.com/GNOME/libgdata.git",
    "libgepub": "https://github.com/GNOME/libgepub.git",
    "libgit2-glib": "https://github.com/GNOME/libgit2-glib.git",
    "libglnx": "https://github.com/GNOME/libglnx.git",
    "libgnome-games-support": "https://github.com/GNOME/libgnome-games-support.git",
    "libgnomekbd": "https://github.com/GNOME/libgnomekbd.git",
    "libgnome-volume-control": "https://github.com/GNOME/libgnome-volume-control.git",
    "libgovirt": "https://github.com/GNOME/libgovirt.git",
    "libgtkmusic": "https://github.com/GNOME/libgtkmusic.git",
    "libgudev": "https://github.com/GNOME/libgudev.git",
    "libgweather": "https://github.com/GNOME/libgweather.git",
    "libgxps": "https://github.com/GNOME/libgxps.git",
    "libhandy": "https://github.com/GNOME/libhandy.git",
    "libhttpseverywhere": "https://github.com/GNOME/libhttpseverywhere.git",
    "libmanette": "https://github.com/GNOME/libmanette.git",
    "libmediaart": "https://github.com/GNOME/libmediaart.git",
    "libnma": "https://github.com/GNOME/libnma.git",
    "libnotify": "https://github.com/GNOME/libnotify.git",
    "libpanel": "https://github.com/GNOME/libpanel.git",
    "libpeas": "https://github.com/GNOME/libpeas.git",
    "librest": "https://github.com/GNOME/librest.git",
    "libsecret": "https://github.com/GNOME/libsecret.git",
    "libshumate": "https://github.com/GNOME/libshumate.git",
    "libsoup": "https://github.com/GNOME/libsoup.git",
    "libwnck": "https://github.com/GNOME/libwnck.git",
    "lightsoff": "https://github.com/GNOME/lightsoff.git",
    "meld": "https://github.com/GNOME/meld.git",
    "mm-common": "https://github.com/GNOME/mm-common.git",
    "msitools": "https://github.com/GNOME/msitools.git",
    "mutter": "https://github.com/GNOME/mutter.git",
    "nautilus": "https://github.com/GNOME/nautilus.git",
    "nautilus-python": "https://github.com/GNOME/nautilus-python.git",
    "network-manager-applet": "https://github.com/GNOME/network-manager-applet.git",
    "niepce": "https://github.com/GNOME/niepce.git",
    "pango": "https://github.com/GNOME/pango.git",
    "pangomm": "https://github.com/GNOME/pangomm.git",
    "phodav": "https://github.com/GNOME/phodav.git",
    "pitivi": "https://github.com/GNOME/pitivi.git",
    "polari": "https://github.com/GNOME/polari.git",
    "pygobject": "https://github.com/GNOME/pygobject.git",
    "quadrapassel": "https://github.com/GNOME/quadrapassel.git",
    "recipes": "https://github.com/GNOME/recipes.git",
    "retro-gtk": "https://github.com/GNOME/retro-gtk.git",
    "rhythmbox": "https://github.com/GNOME/rhythmbox.git",
    "rygel": "https://github.com/GNOME/rygel.git",
    "seahorse": "https://github.com/GNOME/seahorse.git",
    "shotwell": "https://github.com/GNOME/shotwell.git",
    "simple-scan": "https://github.com/GNOME/simple-scan.git",
    "sound-juicer": "https://github.com/GNOME/sound-juicer.git",
    "sushi": "https://github.com/GNOME/sushi.git",
    "swell-foop": "https://github.com/GNOME/swell-foop.git",
    "sysprof": "https://github.com/GNOME/sysprof.git",
    "tali": "https://github.com/GNOME/tali.git",
    "template-glib": "https://github.com/GNOME/template-glib.git",
    "totem": "https://github.com/GNOME/totem.git",
    "totem-pl-parser": "https://github.com/GNOME/totem-pl-parser.git",
    "totem-video-thumbnailer": "https://github.com/GNOME/totem-video-thumbnailer.git",
    "tracker": "https://github.com/GNOME/tracker.git",
    "tracker-miners": "https://github.com/GNOME/tracker-miners.git",
    "vte": "https://github.com/GNOME/vte.git",
    "wing": "https://github.com/GNOME/wing.git",
    "xdg-desktop-portal-gnome": "https://github.com/GNOME/xdg-desktop-portal-gnome.git",
    "yelp-tools": "https://github.com/GNOME/yelp-tools.git",
    "zenity": "https://github.com/GNOME/zenity.git",
}

N_ITERATIONS = 10
MISC_N_TIMES = 100
MS_IN_S = 1000
N_REPEATS_IF_TOO_SHORT = 50
TOO_SHORT_THRESHOLD = 1500


def base_path():
    home = os.path.expanduser("~")
    full_path = home + "/.cache/" + "swift-mesonlsp-benchmarks"
    try:
        os.mkdir(full_path)
    except:
        pass
    return full_path


def heaptrack(command, is_ci):
    base_command = ["heaptrack"]
    if not is_ci:
        base_command += ["--record-only"]

    with subprocess.Popen(
        base_command + command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    ) as prof_process:
        stdout, _ = prof_process.communicate()
        lines = stdout.decode("utf-8").splitlines()
        zstfile = lines[-1].strip().split(" ")[2].replace('"', "")
        with subprocess.Popen(
            ["heaptrack_print", zstfile],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        ) as ana_process:
            stdout, _ = ana_process.communicate()
            lines = stdout.decode("utf-8").splitlines()
            os.remove(zstfile)
            return lines


def clone_project(name, url):
    if os.path.exists(name):
        logging.info("Updating %s", url)
        subprocess.run(
            ["git", "-C", name, "fetch", "--unshallow"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        subprocess.run(
            ["git", "-C", name, "pull"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        return
    logging.info("Cloning %s", url)
    subprocess.run(
        ["git", "clone", "--depth=1", url, name],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=True,
    )


def clone_projects(is_ci):
    for name, url in PROJECTS.items():
        clone_project(name, url)
    for name, url in MISC_PROJECTS.items():
        clone_project(name, url)
    if not is_ci:
        for name, url in ELEMENTARY_PROJECTS.items():
            clone_project(name, url)
        for name, url in GNOME_PROJECTS.items():
            clone_project(name, url)


def basic_analysis(ret, file, commit):
    ret["time"] = time.time()
    ret["commit"] = commit
    ret["size"] = os.path.getsize(file)
    stripped = "/tmp/" + str(uuid.uuid4())
    subprocess.run(["strip", "-s", file, "-o", stripped], check=True)
    ret["stripped_size"] = os.path.getsize(stripped)
    os.remove(stripped)


def quick_parse(ret, absp):
    for proj_name in reduce(lambda x, y: dict(x, **y), (MISC_PROJECTS, PROJECTS)):
        logging.info("Quick parsing %s", proj_name)
        command = [absp, "--path", proj_name + "/meson.build"]
        begin = datetime.datetime.now()
        subprocess.run(
            command,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=True,
        )
        end = datetime.datetime.now()
        duration = (end - begin).total_seconds() * MS_IN_S
        if duration < TOO_SHORT_THRESHOLD:
            logging.info("Too fast, repeating with more iterations: %s", str(duration))
            command = [absp] + (
                [proj_name + "/meson.build"] * (N_REPEATS_IF_TOO_SHORT * 101)
            )
            begin = datetime.datetime.now()
            subprocess.run(
                command,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                check=True,
            )
            end = datetime.datetime.now()
            duration = (
                (end - begin).total_seconds() * MS_IN_S
            ) / N_REPEATS_IF_TOO_SHORT
            logging.info("New duration: %s", str(duration))
        ret["quick"][proj_name] = duration


def misc_parse(ret, absp, is_ci):
    projs = []
    for projname in MISC_PROJECTS:
        projs.append(projname + "/meson.build")
    command = [absp] + (projs * MISC_N_TIMES)
    logging.info("Parsing misc")
    begin = datetime.datetime.now()
    subprocess.run(
        command,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=True,
    )
    end = datetime.datetime.now()
    logging.info("Tracing using heaptrack for misc")
    lines = heaptrack(command, is_ci)
    if lines[-1].startswith("suppressed leaks:"):
        lines = lines[:-1]
    ret["misc"]["parsing"] = (end - begin).total_seconds() * MS_IN_S
    ret["misc"]["memory_allocations"] = int(lines[-5].split(" ")[4])
    ret["misc"]["temporary_memory_allocations"] = int(lines[-4].split(" ")[3])
    ret["misc"]["peak_heap"] = lines[-3].split(" ")[4]
    ret["misc"]["peak_rss"] = lines[-2].split("): ")[1]


def projects_parse(ret, absp, is_ci):
    for proj_name in PROJECTS:
        logging.info("Parsing %s", proj_name)
        projobj = {}
        projobj["name"] = proj_name
        begin = datetime.datetime.now()
        command = [absp, "--path", proj_name + "/meson.build"]
        for i in range(0, N_ITERATIONS):
            logging.info("Iteration %s", str(i))
            subprocess.run(
                command,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                check=True,
            )
        end = datetime.datetime.now()
        projobj["parsing"] = (end - begin).total_seconds() * MS_IN_S
        logging.info("Tracing using heaptrack for %s", proj_name)
        lines = heaptrack(command, is_ci)
        if lines[-1].startswith("suppressed leaks:"):
            lines = lines[:-1]
        projobj["memory_allocations"] = int(lines[-5].split(" ")[4])
        projobj["temporary_memory_allocations"] = int(lines[-4].split(" ")[3])
        projobj["peak_heap"] = lines[-3].split(" ")[4]
        projobj["peak_rss"] = lines[-2].split("): ")[1]
        ret["projects"].append(projobj)


def parse_project_collection(absp, projs):
    command = [absp]
    for projname in projs.keys():
        for _ in range(0, 100):
            command.append(projname + "/meson.build")
    logging.info("Parsing project collection")
    ret = {}
    begin = datetime.datetime.now()
    subprocess.run(
        command,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=True,
    )
    end = datetime.datetime.now()
    logging.info("Tracing parsing of collection using heaptrack")
    lines = heaptrack(command, False)
    if lines[-1].startswith("suppressed leaks:"):
        lines = lines[:-1]
    ret["parsing"] = (end - begin).total_seconds() * MS_IN_S
    ret["memory_allocations"] = int(lines[-5].split(" ")[4])
    ret["temporary_memory_allocations"] = int(lines[-4].split(" ")[3])
    ret["peak_heap"] = lines[-3].split(" ")[4]
    ret["peak_rss"] = lines[-2].split("): ")[1]
    return ret


def parse_gnome_elementary(ret, absp):
    ret["floss"] = {}
    ret["floss"]["elementary"] = parse_project_collection(absp, ELEMENTARY_PROJECTS)
    ret["floss"]["gnome"] = parse_project_collection(absp, GNOME_PROJECTS)


def analyze_file(file, commit, is_ci):
    logging.info("Base path: %s", base_path())
    ret = {}
    basic_analysis(ret, file, commit)
    absp = os.path.abspath(file)
    os.chdir(base_path())
    clone_projects(is_ci)
    ret["quick"] = {}
    quick_parse(ret, absp)
    ret["misc"] = {}
    misc_parse(ret, absp, is_ci)
    ret["projects"] = []
    projects_parse(ret, absp, is_ci)
    if not is_ci:
        parse_gnome_elementary(ret, absp)
    print(json.dumps(ret))


def main():
    parser = argparse.ArgumentParser(
        prog="collect_perf_data.py",
        description="Collect performance/memory usage characteristics",
    )
    parser.add_argument("--ci", action="store_true")
    parser.add_argument("filename")
    parser.add_argument("commit")
    args = parser.parse_args()
    analyze_file(args.filename, args.commit, args.ci)


if __name__ == "__main__":
    logging.basicConfig(
        format="%(asctime)s %(levelname)-8s %(message)s", level=logging.INFO
    )
    main()
