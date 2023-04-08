public class MesonDocs {
  public var docs: [String: String] = [:]
  public let typeDocs: [String: String] = [
    "build_machine":
      "Provides information about the build machine -- the machine that is doing the actual compilation.",
    "host_machine":
      "Provides information about the host machine -- the machine on which the compiled binary will run.",
    "target_machine":
      "Provides information about the target machine -- the machine on which the compiled binary's output will run.",
    "meson":
      "The `meson` object allows you to introspect various properties of the system. This object is always mapped in the `meson` variable.",
    "any":
      "A placeholder representing all types. This includes builtin, as well as returned objects.",
    "bool": "A boolean object which is either `true` or `false`",
    "dict":
      "Stores a mapping of strings to other objects. You can also iterate over dictionaries with the `foreach` statement.",
    "int":
      "All integer numbers. Meson supports only integer numbers. Hexadecimal, binary and octal literals are supported.",
    "list":
      "An array of elements. An array can contain an arbitrary number of objects of any type. Note appending to an array will always create a new array object instead of modifying the original since all objects in Meson are immutable.",
    "str": "Strings are immutable, all operations return their results as a new string.",
    "void": "Indicates that the function does not return anything. Similar to `void` in C and C++",
    "alias_tgt": "Opaque object returned by `alias_target()`.",
    "both_libs": "Container for both a static and shared library.",
    "build_tgt":
      "A build target is either an executable, shared library, static library, both shared and static library or shared module.",
    "cfg_data":
      "This object encapsulates configuration values to be used for generating configuration files.",
    "compiler":
      "This object is returned by `meson.get_compiler()`. It represents a compiler for a given language and allows you to query its properties.",
    "custom_idx": "References a specific output file of a `custom_tgt` object.",
    "custom_tgt": "This object is returned by `custom_target()`.",
    "dep": "Abstract representation of a dependency.",
    "disabler":
      "A disabler object is an object that behaves in much the same way as NaN numbers do in floating point math. That is when used in any statement (function call, logical op, etc) they will cause the statement evaluation to immediately short circuit to return a disabler object.",
    "env":
      "This object is returned by `environment()` and stores detailed information about how environment variables should be set during tests. It should be passed as the env keyword argument to tests and other functions.",
    "exe": "An executable", "external_program": "Opaque object representing an external program",
    "extracted_obj": "Opaque object representing extracted object files from build targets",
    "feature": "Meson object representing a `feature` option.",
    "file": "Opaque object that stores the path to an existing file",
    "generated_list": "Opaque object representing the result of a `generator.process()` call.",
    "generator":
      "This object is returned by `generator()` and contains a generator that is used to transform files from one type to another by an executable (e.g. idl files into source code and headers).",
    "inc": "Opaque wrapper for storing include directories", "jar": "A Java JAR build target",
    "lib": "Represents either a shared or static library", "module": "Base type for all modules.",
    "range": "Opaque object that can be used in a loop and accessed via `[num]`.",
    "run_tgt": "Opaque object returned by `run_target()`.",
    "runresult":
      "This object encapsulates the result of trying to compile and run a sample piece of code with `compiler.run()` or `run_command()`.",
    "structured_src": "Opaque object returned by `structured_sources()`.",
    "subproject":
      "This object is returned by `subproject()` and is an opaque object representing it.",
    "tgt": "Opaque base object for all Meson targets",
    "cmake_module":
      "This module provides helper tools for generating cmake package files. It also supports the usage of CMake based subprojects, similar to the normal Meson subprojects.",
    "cmake_subproject": "This object is returned by the `cmake_module.subproject()`",
    "cmake_subprojectoptions":
      "This object is returned by the `cmake_module.subproject_options()` method and consumed by the `options` kwarg of the `subproject` method.",
    "cuda_module":
      "This module provides helper functionality related to the CUDA Toolkit and building code using it.",
    "dlang_module":
      "This module provides tools related to the D programming language.\n\nThe module only exposes one function, `generate_dub_file`, used to automatically generate Dub configuration files.",
    "fs_module": "This module provides functions to inspect the file system.",
    "gnome_module":
      "This module provides helper tools for build operations needed when building Gnome/GLib programs.",
    "hotdoc_module":
      "This module provides helper functions for generating documentation using hotdoc.",
    "icestorm_module":
      "This module provides an experimental method to create FPGA bitstreams using the IceStorm suite of tools.",
    "i18n_module": "This module provides internationalisation and localisation functionality.",
    "java_module": "This module provides methods for generating headers for the JNI.",
    "keyval_module":
      "This module parses files consisting of a series of `key=value` lines. One use of this module is to load kconfig configurations in Meson projects.",
    "pkgconfig_module": "This module is a simple generator for pkg-config files.",
    "python3_module":
      "This module provides support for dealing with Python 3. This module is deprecated and replaced by the `python` module.",
    "python_module":
      "This module provides support for finding and building extensions against python installations, be they python 2 or 3.",
    "qt4_module":
      "This module provides support for Qt4's moc, uic and rcc tools. It is used identically to the Qt 5 module.",
    "qt5_module":
      "The Qt5 module provides tools to automatically deal with the various tools and steps required for Qt.",
    "qt6_module":
      "The Qt6 module provides tools to automatically deal with the various tools and steps required for Qt.",
    "rust_module":
      "The rust module provides helper to integrate rust code into Meson. The goal is to make using rust in Meson more pleasant, while still remaining mesonic, this means that it attempts to make Rust work more like Meson, rather than Meson work more like rust.",
    "simd_module":
      "This module provides helper functionality to build code with SIMD instructions. Available since 0.42.0.",
    "sourceset_module":
      "This module provides support for building many targets against a single set of files; the choice of which files to include in each target depends on the contents of a dictionary or a `configuration_data` object.",
    "sourceset":
      "The `source_set` object provides methods to add files to a source set and to query it. The source set becomes immutable after any method but `add` is called.",
    "source_configuration":
      "The `source_configuration` object provides methods to query the result of an `apply` operation on a source set.",
    "windows_module": "This module provides functionality used to build applications for Windows.",
    "wayland_module":
      "This module provides helper functions to find wayland protocol xmls and to generate .c and .h files using wayland-scanner",
    "python_installation":
      "The python_installation object is an external_program, with several added methods.",
  ]

  public init() {
    FunctionDocProvider().addToDict(dict: &self.docs)
    BoolDocProvider().addToDict(dict: &self.docs)
    DictDocProvider().addToDict(dict: &self.docs)
    IntDocProvider().addToDict(dict: &self.docs)
    ListDocProvider().addToDict(dict: &self.docs)
    StrDocProvider().addToDict(dict: &self.docs)
    BuildMachineDocProvider().addToDict(dict: &self.docs)
    MesonDocProvider().addToDict(dict: &self.docs)
    ObjectDocProvider().addToDict(dict: &self.docs)
    BuiltinKwargDocProvider().addToDict(dict: &self.docs)
    CMakeDocProvider().addToDict(dict: &self.docs)
    CudaDocProvider().addToDict(dict: &self.docs)
    DlangDocProvider().addToDict(dict: &self.docs)
    ExternalProjectDocProvider().addToDict(dict: &self.docs)
    FsDocProvider().addToDict(dict: &self.docs)
    GnomeDocProvider().addToDict(dict: &self.docs)
    HotdocDocProvider().addToDict(dict: &self.docs)
    I18nDocProvider().addToDict(dict: &self.docs)
    IcestormDocProvider().addToDict(dict: &self.docs)
    JavaDocProvider().addToDict(dict: &self.docs)
    KeyvalDocProvider().addToDict(dict: &self.docs)
    PkgconfigDocProvider().addToDict(dict: &self.docs)
    PythonDocProvider().addToDict(dict: &self.docs)
    QtDocProvider().addToDict(dict: &self.docs)
    RustDocProvider().addToDict(dict: &self.docs)
    SimdDocProvider().addToDict(dict: &self.docs)
    SourceSetDocProvider().addToDict(dict: &self.docs)
    WaylandDocProvider().addToDict(dict: &self.docs)
    WindowsDocProvider().addToDict(dict: &self.docs)
    ModuleKwargDocProvider().addToDict(dict: &self.docs)
  }

  public func findDocs(id: String) -> String? { return self.docs[id] }
}
