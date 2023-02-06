import MesonAST

public class ImportTypeAnalyzer: MesonTypeAnalyzer {
  public func derive(node: Node, fn: Function, options: [MesonOption], ns: TypeNamespace) -> [Type]
  {
    if let fe = node as? FunctionExpression, let feid = fe.id as? IdExpression, feid.id == "import"
    {
      if let alo = fe.argumentList, let al = alo as? ArgumentList, !al.args.isEmpty {
        let arg0 = al.args[0]
        if let sl = arg0 as? StringLiteral {
          let t = sl.contents()
          switch t {
          case "cmake": return [ns.types["cmake_module"]!]
          case "fs": return [ns.types["fs_module"]!]
          case "gnome": return [ns.types["gnome_module"]!]
          case "i18n": return [ns.types["i18n_module"]!]
          case "rust": return [ns.types["rust_module"]!]
          case "unstable-rust": return [ns.types["rust_module"]!]
          case "python": return [ns.types["python_module"]!]
          case "python3": return [ns.types["python3_module"]!]
          case "pkgconfig": return [ns.types["pkgconfig_module"]!]
          case "keyval": return [ns.types["keyval_module"]!]
          case "dlang": return [ns.types["dlang_module"]!]
          case "unstable-external_project": return [ns.types["external_project_module"]!]
          case "hotdoc": return [ns.types["hotdoc_module"]!]
          case "java": return [ns.types["java_module"]!]
          case "windows": return [ns.types["windows_module"]!]
          case "cuda": return [ns.types["cuda_module"]!]
          case "unstable-cuda": return [ns.types["cuda_module"]!]
          case "icestorm": return [ns.types["icestorm_module"]!]
          case "unstable-icestorm": return [ns.types["icestorm_module"]!]
          case "qt4": return [ns.types["qt4_module"]!]
          case "qt5": return [ns.types["qt5_module"]!]
          case "qt6": return [ns.types["qt6_module"]!]
          case "unstable-wayland": return [ns.types["wayland_module"]!]
          case "unstable-simd": return [ns.types["simd_module"]!]
          case "sourceset": return [ns.types["sourceset_module"]!]
          default: return fn.returnTypes
          }
        }
      }
    }
    return fn.returnTypes
  }
}
