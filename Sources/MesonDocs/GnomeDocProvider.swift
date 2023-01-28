class GnomeDocProvider: DocProvider {
  func addToDict(dict: inout [String: String]) {
    dict["gnome_module.compile_resources"] =
      "This function compiles resources specified in an XML file into code that can be embedded inside the main binary. Similar a build target it takes two positional arguments. The first one is the name of the resource and the second is the XML file containing the resource definitions."
    dict["gnome_module.generate_gir"] = "Generates GObject introspection data."
    dict["gnome_module.genmarshal"] =
      "Generates a marshal file using the `glib-genmarshal` tool. The first argument is the basename of the output files."
    dict["gnome_module.mkenums"] =
      "Generates enum files for GObject using the `glib-mkenums` tool.\n\nMost libraries and applications will be using the same standard template with only minor tweaks, in which case the `gnome.mkenums_simple()` convenience method can be used instead."
    dict["gnome_module.compile_schemas"] =
      "When called, this method will compile the gschemas in the current directory. Note that this is not for installing schemas and is only useful when running the application locally for example during tests."
    dict["gnome_module.gdbus_codegen"] =
      "Compiles the given XML schema into gdbus source code. Takes two positional arguments, the first one specifies the base name to use while creating the output source and header and the second specifies one XML file."
    dict["gnome_module.generate_vapi"] =
      "Creates a VAPI file from gir. The first argument is the name of the library."
    dict["gnome_module.yelp"] =
      "Installs help documentation for Yelp using itstool and gettext. The first argument is the project id."
    dict["gnome_module.gtkdoc"] =
      "Compiles and installs gtkdoc documentation into `prefix/share/gtk-doc/html`. Takes one positional argument: The name of the module."
    dict["gnome_module.gtkdoc_html_dir"] =
      "Takes as argument a module name and returns the path where that module's HTML files will be installed. Usually used with `install_data` to install extra files, such as images, to the output directory."
    dict["gnome_module.post_install"] = "Post-install update of various system wide caches."
  }
}
