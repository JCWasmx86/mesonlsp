public struct GNOMEModule: AbstractObject {
  public let name: String = "gnome_module"
  public let parent: AbstractObject? = Module()
  public var methods: [Method] = []

  public init() {
    self.methods = [
      Method(
        name: "compile_resources",
        parent: self,
        returnTypes: [ListType(types: [BuildTgt()])],
        args: [
          PositionalArgument(name: "id", types: [Str()]),
          PositionalArgument(
            name: "input",
            types: [ListType(types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()])]
          ), Kwarg(name: "c_name", opt: true, types: [Str()]),
          Kwarg(
            name: "dependencies",
            opt: true,
            types: [ListType(types: [File(), CustomTgt(), CustomIdx()])]
          ), Kwarg(name: "export", opt: true, types: [BoolType()]),
          Kwarg(name: "extra_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "gresource_bundle", opt: true, types: [BoolType()]),
          Kwarg(name: "install", opt: true, types: [BoolType()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(name: "install_header", opt: true, types: [BoolType()]),
          Kwarg(name: "source_dir", opt: true, types: [ListType(types: [Str()])]),
        ]
      ),
      Method(
        name: "generate_gir",
        parent: self,
        returnTypes: [ListType(types: [CustomTgt()])],
        args: [
          PositionalArgument(name: "file", varargs: true, types: [Exe(), Lib()]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()])]),
          Kwarg(name: "extra_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "export_packages", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(
            name: "sources",
            opt: true,
            types: [ListType(types: [Str(), File(), CustomTgt(), CustomIdx()])]
          ), Kwarg(name: "nsversion", opt: true, types: [Str()]),
          Kwarg(name: "namespace", opt: true, types: [Str()]),
          Kwarg(name: "identifier_prefix", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "includes", opt: true, types: [ListType(types: [Str(), CustomTgt()])]),
          Kwarg(name: "header", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "symbol_prefix", opt: true, types: [Str()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Str(), Inc()])]),
          Kwarg(name: "install", opt: true, types: [BoolType()]),
          Kwarg(name: "install_gir", opt: true, types: [BoolType()]),
          Kwarg(name: "install_dir_gir", opt: true, types: [Str(), BoolType()]),
          Kwarg(name: "install_typelib", opt: true, types: [BoolType()]),
          Kwarg(name: "install_dir_typelib", opt: true, types: [Str(), BoolType()]),
          Kwarg(name: "link_with", opt: true, types: [ListType(types: [Lib()])]),
          Kwarg(name: "symbok_prefix", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "fatal_warnings", opt: true, types: [BoolType()]),
        ]
      ),
      Method(
        name: "genmarshal",
        parent: self,
        returnTypes: [ListType(types: [CustomTgt()])],
        args: [
          PositionalArgument(name: "basename", types: [Str()]),
          Kwarg(name: "depends", opt: true, types: [ListType(types: [BuildTgt(), CustomTgt()])]),
          Kwarg(name: "depend_files", opt: true, types: [Str(), File()]),
          Kwarg(name: "extra_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(name: "install_header", opt: true, types: [BoolType()]),
          Kwarg(name: "internal", opt: true, types: [BoolType()]),
          Kwarg(name: "nostdinc", opt: true, types: [BoolType()]),
          Kwarg(name: "prefix", types: [ListType(types: [Str()])]),
          Kwarg(name: "skip_source", opt: true, types: [BoolType()]),
          Kwarg(name: "sources", types: [ListType(types: [Str(), File()])]),
          Kwarg(name: "stdinc", opt: true, types: [BoolType()]),
          Kwarg(name: "valist_marshallers", opt: true, types: [BoolType()]),
        ]
      ),
      Method(
        name: "mkenums",
        parent: self,
        returnTypes: [ListType(types: [CustomTgt()])],
        args: [
          PositionalArgument(name: "name", types: [Str()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(name: "install_header", opt: true, types: [BoolType()]),
          Kwarg(
            name: "sources",
            types: [ListType(types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()])]
          ), Kwarg(name: "symbol_prefix", opt: true, types: [Str()]),
          Kwarg(name: "identifier_prefix", opt: true, types: [Str()]),
          Kwarg(name: "depends", opt: true, types: [ListType(types: [BuildTgt(), CustomTgt()])]),
          Kwarg(name: "c_template", opt: true, types: [File(), Str()]),
          Kwarg(name: "h_template", opt: true, types: [File(), Str()]),
          Kwarg(name: "comments", opt: true, types: [Str()]),
          Kwarg(name: "eprod", opt: true, types: [Str()]),
          Kwarg(name: "fhead", opt: true, types: [Str()]),
          Kwarg(name: "fprod", opt: true, types: [Str()]),
          Kwarg(name: "ftail", opt: true, types: [Str()]),
          Kwarg(name: "vhead", opt: true, types: [Str()]),
          Kwarg(name: "vprod", opt: true, types: [Str()]),
          Kwarg(name: "vtail", opt: true, types: [Str()]),
        ]
      ),
      Method(
        name: "mkenums_simple",
        parent: self,
        returnTypes: [ListType(types: [CustomTgt()])],
        args: [
          PositionalArgument(name: "name", types: [Str()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(name: "install_header", opt: true, types: [BoolType()]),
          Kwarg(
            name: "sources",
            types: [ListType(types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()])]
          ), Kwarg(name: "symbol_prefix", opt: true, types: [Str()]),
          Kwarg(name: "identifier_prefix", opt: true, types: [Str()]),
          Kwarg(name: "body_prefix", opt: true, types: [Str()]),
          Kwarg(name: "decorator", opt: true, types: [Str()]),
          Kwarg(name: "function_prefix", opt: true, types: [Str()]),
          Kwarg(name: "header_prefix", opt: true, types: [Str()]),
        ]
      ),
      Method(
        name: "compile_schemas",
        parent: self,
        returnTypes: [CustomTgt()],
        args: [
          Kwarg(name: "build_by_default", opt: true, types: [BoolType()]),
          Kwarg(name: "depend_files", opt: true, types: [Str(), File()]),
        ]
      ),
      Method(
        name: "gdbus_codegen",
        parent: self,
        returnTypes: [ListType(types: [CustomTgt()])],
        args: [
          PositionalArgument(name: "name", types: [Str()]),
          PositionalArgument(
            name: "file",
            varargs: true,
            opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ), Kwarg(name: "extra_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "interface_prefix", opt: true, types: [Str()]),
          Kwarg(name: "namespace", opt: true, types: [Str()]),
          Kwarg(name: "object_manager", opt: true, types: [BoolType()]),
          Kwarg(
            name: "annotations",
            opt: true,
            types: [ListType(types: [ListType(types: [Str()])])]
          ), Kwarg(name: "install_header", opt: true, types: [BoolType()]),
          Kwarg(name: "docbook", opt: true, types: [Str()]),
          Kwarg(name: "autocleanup", opt: true, types: [Str()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(
            name: "sources",
            opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ),
        ]
      ),
      Method(
        name: "generate_vapi",
        parent: self,
        returnTypes: [Dep()],
        args: [
          PositionalArgument(name: "name", types: [Str()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(name: "install", opt: true, types: [BoolType()]),
          Kwarg(name: "sources", types: [ListType(types: [Str(), CustomTgt()])]),
          Kwarg(name: "vapi_dirs", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "metadata_dirs", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "gir_dirs", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "packages", opt: true, types: [ListType(types: [Str(), Dep()])]),
        ]
      ),
      Method(
        name: "yelp",
        parent: self,
        returnTypes: [],
        args: [
          PositionalArgument(name: "name", types: [Str()]),
          PositionalArgument(name: "file", varargs: true, opt: true, types: [Str()]),
          Kwarg(name: "languages", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "media", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "sources", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "symlink_media", opt: true, types: [BoolType()]),
        ]
      ),
      Method(
        name: "gtkdoc",
        parent: self,
        returnTypes: [ListType(types: [CustomTgt()])],
        args: [
          PositionalArgument(name: "name", types: [Str()]),
          Kwarg(name: "c_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "check", opt: true, types: [BoolType()]),
          Kwarg(
            name: "content_files",
            opt: true,
            types: [ListType(types: [Str(), File(), GeneratedList(), CustomTgt(), CustomIdx()])]
          ), Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep(), Lib()])]),
          Kwarg(
            name: "expand_content_files",
            opt: true,
            types: [ListType(types: [Str(), File()])]
          ), Kwarg(name: "fixref_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "gobject_typesfile", opt: true, types: [ListType(types: [Str(), File()])]),
          Kwarg(name: "html_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "html_assets", opt: true, types: [ListType(types: [Str(), File()])]),
          Kwarg(name: "ignore_headers", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Str(), Inc()])]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(name: "install", opt: true, types: [BoolType()]),
          Kwarg(name: "main_sgml", opt: true, types: [Str()]),
          Kwarg(name: "main_xml", opt: true, types: [Str()]),
          Kwarg(name: "fixxref_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "mkdb_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "mode", opt: true, types: [Str()]),
          Kwarg(name: "module_version", opt: true, types: [Str()]),
          Kwarg(name: "namespace", opt: true, types: [Str()]),
          Kwarg(name: "scan_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "scanobj_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "src_dir", opt: true, types: [ListType(types: [Str(), Inc()])]),
        ]
      ),
      Method(
        name: "gtkdoc_html_dir",
        parent: self,
        returnTypes: [Str()],
        args: [PositionalArgument(name: "name", types: [Str()])]
      ),
      Method(
        name: "post_install",
        parent: self,
        returnTypes: [],
        args: [
          Kwarg(name: "glib_compile_schemas", opt: true, types: [BoolType()]),
          Kwarg(name: "gtk_update_icon_cache", opt: true, types: [BoolType()]),
          Kwarg(name: "update_desktop_database", opt: true, types: [BoolType()]),
          Kwarg(name: "update_mime_database", opt: true, types: [BoolType()]),
          Kwarg(name: "gio_querymodules", opt: true, types: [ListType(types: [Str()])]),
        ]
      ),
    ]
  }
}
