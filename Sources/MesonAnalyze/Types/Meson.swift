public class Meson: AbstractObject {
  public let name: String = "meson"
  public let parent: AbstractObject? = nil
  public var methods: [Method] = []

  public init() {
    self.methods = [
      Method(name: "add_devenv", parent: self),
      Method(name: "add_dist_script", parent: self),
      Method(name: "add_install_script", parent: self),
      Method(name: "add_postconf_script", parent: self),
      Method(
        name: "backend", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "build_root", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "can_run_host_binaries", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(
        name: "current_build_dir", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "current_source_dir", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "get_compiler", parent: self,
        returnTypes: [
          Compiler()
        ]),
      Method(
        name: "get_cross_property", parent: self,
        returnTypes: [
          `Any`()
        ]),
      Method(
        name: "get_external_property", parent: self,
        returnTypes: [
          `Any`()
        ]),
      Method(
        name: "global_build_root", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "global_source_root", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "has_exe_wrapper", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(
        name: "has_external_property", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(name: "install_dependency_manifest", parent: self),
      Method(
        name: "is_cross_build", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(
        name: "is_subproject", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(
        name: "is_unity", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(name: "override_dependency", parent: self),
      Method(name: "override_find_program", parent: self),
      Method(
        name: "project_build_root", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "project_license", parent: self,
        returnTypes: [
          ListType(types: [Str()])
        ]),
      Method(name: "project_license_files", parent: self),
      Method(
        name: "project_name", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "project_source_root", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "project_version", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "source_root", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "version", parent: self,
        returnTypes: [
          Str()
        ]),
    ]
  }
}
