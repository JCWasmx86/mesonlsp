import Foundation
import IOUtils
import Logging
import Wrap

public class SubprojectState {
  static let LOG: Logger = Logger(label: "Subproject::SubprojectState")

  private var subprojects: [Subproject] = []
  private var errors: [Error] = []

  // swiftlint:disable cyclomatic_complexity
  public init(rootDir: String) throws {
    let p = Path(rootDir + "/subprojects")
    if !p.exists {
      Self.LOG.info("No subprojects directory found")
      return
    }
    let url = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(
      ".cache",
      isDirectory: true
    ).appendingPathComponent("swift-mesonlsp", isDirectory: true).appendingPathComponent(
      "__wrap_setup_cache__",
      isDirectory: true
    )
    do { try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true) } catch
    {}
    let setupCache = Path(url.absoluteURL.path)
    let packagefiles = Path(p.description + "/packagefiles").absolute().description
    let children = try p.children()
    for child in children {
      if child.isFile && child.lastComponent.hasSuffix(".wrap") {
        let wfp = WrapFileParser(path: child.absolute().description)
        do {
          let w = try wfp.parse()
          let cachedPath = Path(setupCache.description + Path.separator + w.wrapHash)
          if !cachedPath.exists {
            Self.LOG.info("Unable to find cached setup wrap for hash \(w.wrapHash)")
            self.subprojects.append(
              try WrapBasedSubproject(
                wrapName: child.lastComponentWithoutExtension,
                wrap: w,
                packagefiles: packagefiles,
                parent: nil,
                destDir: cachedPath.description
              )
            )
          } else {
            Self.LOG.info("Found cached wrap for hash \(w.wrapHash)")
            self.subprojects.append(
              try CachedSubproject(
                name: child.lastComponentWithoutExtension,
                parent: nil,
                path: cachedPath.description
              )
            )
          }
        } catch let error { self.errors.append(error) }
      } else {
        continue
      }
      while true {
        let old = self.subprojects.count
        for s in self.subprojects {
          do { try s.discoverMore(state: self) } catch let error { self.errors.append(error) }
        }
        if self.subprojects.count == old { break }
      }
    }
    for child in children {
      if child.isDirectory
        && (child.lastComponent != "packagefiles" && child.lastComponent != "packagecache")
        && !self.alreadyRegistered(child.lastComponent)
      {
        self.subprojects.append(try FolderSubproject(name: child.lastComponent, parent: nil))
      } else {
        continue
      }
      while true {
        let old = self.subprojects.count
        for s in self.subprojects {
          do { try s.discoverMore(state: self) } catch let error { self.errors.append(error) }
        }
        if self.subprojects.count == old { break }
      }
    }
    for err in self.errors { Self.LOG.info("Got error \(err)") }
    for s in self.subprojects { Self.LOG.info("Got subproject \(s.description)") }
  }
  // swiftlint:enable cyclomatic_complexity

  private func alreadyRegistered(_ dir: String) -> Bool {
    for s in self.subprojects where s.name == dir { return true }
    return false
  }
}
