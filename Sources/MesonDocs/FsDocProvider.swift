class FsDocProvider: DocProvider {
  func addToDict(dict: inout [String: String]) {
    dict["fs_module.exists"] =
      "Takes a single string argument and returns true if an entity with that name exists on the file system. This can be a file, directory or a special entry such as a device node."
    dict["fs_module.is_dir"] =
      "Takes a single string argument and returns true if a directory with that name exists on the file system."
    dict["fs_module.is_file"] =
      "Takes a single string argument and returns true if an file with that name exists on the file system."
    dict["fs_module.is_symlink"] =
      "Takes a single string of `files()` argument and returns true if the path pointed to by the string is a symbolic link"
    dict["fs_module.is_absolute"] =
      "Return a boolean indicating if the path string or `files()` specified is absolute, WITHOUT expanding `~`."
    dict["fs_module.hash"] = "Returns a string containing the hexadecimal hash digest of a file"
    dict["fs_module.size"] = "Returns the size of the file in bytes"
    dict["fs_module.is_samepath"] = "Returns true, if both paths resolve to the same path."
    dict["fs_module.expanduser"] =
      "A path string with a leading `~` is expanded to the user home directory"
    dict["fs_module.as_posix"] = "Assumes a windows path, even if on a Unix-like system"
    dict["fs_module.replace_suffix"] =
      "The `replace_suffix` method is a string manipulation convenient for filename modifications. It allows changing the filename suffix."
    dict["fs_module.parent"] = "Returns the parent directory (i.e. dirname)."
    dict["fs_module.name"] = "Returns the last component of the path (i.e. basename)."
    dict["fs_module.stem"] =
      "Returns the last component of the path, dropping the last part of the suffix"
    dict["fs_module.read"] =
      "Returns a string with the contents of the given path. If encoding is not given, UTF-8 is assumed."
    dict["fs_module.copyfile"] =
      "Copy a file from the source directory to the build directory at build time"
  }
}
