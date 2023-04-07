import Foundation
import IOUtils
import Logging
import Subproject

internal class FileMapper {
  static let LOG = Logger(label: "LanguageServer::FileMapper")
  internal var subprojects: SubprojectState?
  internal var rootDir = ""

  internal init() {}

  internal func fromCacheToSubproject(file: String) -> String {
    let p = Path(file).absolute().normalize()
    if !self.rootDir.isEmpty, let state = self.subprojects {
      for s in state.subprojects {
        // These are automatically mapped into the project directory
        if s is FolderSubproject { continue }
        var pp = ""
        if let csp = s as? CachedSubproject {
          if let children = try? Path(csp.cachedPath).children(), !children.isEmpty {
            pp =
              Path(csp.cachedPath + "/\(children[0].lastComponent)/").absolute().normalize()
              .description
          } else {
            continue
          }
        } else if let wbsp = s as? WrapBasedSubproject {
          pp =
            Path(wbsp.destDir + "/" + wbsp.wrap.directoryNameAfterSetup + "/").absolute()
            .normalize().description
        } else {
          fatalError("Unimplemented")
        }
        let real = Path(pp).parent().absolute().normalize().description
        if p.description.hasPrefix(real) {
          let relative = p.description.replacingOccurrences(of: real, with: "").dropFirst()
          Self.LOG.warning("Relative path is now: \(relative)")
          let p1 = Path(self.rootDir + "/subprojects/" + relative).absolute().normalize()
            .description
          Self.LOG.info("Mapped from \(p) to \(p1)")
          return p1
        }
      }
    }
    return p.description
  }

  internal func fromSubprojectToCache(file: String) -> String {
    let p = Path(file).absolute().normalize()
    if !self.rootDir.isEmpty, let state = self.subprojects {
      for s in state.subprojects {
        // These are automatically mapped into the project directory
        if s is FolderSubproject { continue }
        let relativePath = p.description.replacingOccurrences(of: self.rootDir, with: "")
          .dropFirst().description
        if relativePath.hasPrefix("subprojects"), let s = self.subprojects {
          let parts = relativePath.split(separator: Path.separator[0])
          // At least subprojects/<name>/meson.build
          if parts.count < 3 { return p.description }
          let name = parts[1]
          for sp in s.subprojects where sp.realpath.hasPrefix("subprojects/\(name)/") {
            if sp is FolderSubproject { continue }
            Self.LOG.info("Found subproject `\(sp.description)` for path \(p)")
            let joined = parts[2...].joined(separator: "/")
            let p1: String
            if let csp = sp as? CachedSubproject {
              if let children = try? Path(csp.cachedPath).children(), !children.isEmpty {
                p1 =
                  Path(csp.cachedPath + "/\(children[0].lastComponent)/\(joined)").absolute()
                  .normalize().description
              } else {
                continue
              }
            } else if let wbsp = sp as? WrapBasedSubproject {
              p1 =
                Path(wbsp.destDir + "/" + wbsp.wrap.directoryNameAfterSetup + "/" + joined)
                .absolute().normalize().description
            } else {
              fatalError("Unimplemented")
            }
            Self.LOG.info("Mapped from \(p) to \(p1)")
            return p1
          }
        }
      }
    }
    return p.description
  }
}
