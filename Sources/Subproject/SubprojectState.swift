import IOUtils
import Logging
import Wrap

public class SubprojectState {
  static let LOG: Logger = Logger(label: "Subproject::SubprojectState")

  private var subprojects: [Subproject] = []
  private var errors: [Error] = []

  public init(rootDir: String) throws {
    let p = Path(rootDir + "/subprojects")
    if !p.exists {
      Self.LOG.info("No subprojects directory found")
      return
    }
    let children = try p.children()
    for child in children where child.isFile && child.absolute().description.hasSuffix(".wrap") {
      Self.LOG.info("Found wrap file \(child.absolute())")
      let wfp = WrapFileParser(path: child.absolute().description)
      do {
        let wrap = try wfp.parse()
        let sb = try Subproject(
          name: child.lastComponentWithoutExtension,
          wrap: wrap,
          projectRoot: rootDir
        )
        self.subprojects.append(sb)
      } catch let error { self.errors.append(error) }
    }
    for child in children
    where child.isDirectory && child.lastComponentWithoutExtension != "packagefiles"
      && !self.alreadyRegistered(child.lastComponentWithoutExtension)
    {
      Self.LOG.info("Found subproject \(child.absolute())")
      do {
        let sb = try Subproject(
          name: child.lastComponentWithoutExtension,
          wrap: nil,
          projectRoot: rootDir
        )
        self.subprojects.append(sb)
      } catch let error { self.errors.append(error) }
    }
    while true {
      let old = self.subprojects.count
      for s in self.subprojects { try s.discoverMore(state: self) }
      if self.subprojects.count == old { break }
    }
  }

  private func alreadyRegistered(_ dir: String) -> Bool {
    for s in self.subprojects {
      if s.name == dir { return true } else if let w = s.wrap, w.directoryNameAfterSetup == dir {}
    }
    return false
  }

  internal func registerSubproject(_ parent: Subproject, _ childPath: Path) {
    if childPath.isFile {
      let wfp = WrapFileParser(path: childPath.absolute().description)
      do {
        let wrap = try wfp.parse()
        let sb = try Subproject(
          name: childPath.lastComponentWithoutExtension,
          wrap: wrap,
          projectRoot: childPath.parent().parent().description
        )
        self.subprojects.append(sb)
      } catch let error { self.errors.append(error) }
    } else if childPath.isDirectory {
      do {
        let sb = try Subproject(
          name: childPath.lastComponentWithoutExtension,
          wrap: nil,
          projectRoot: childPath.parent().parent().description
        )
        self.subprojects.append(sb)
      } catch let error { self.errors.append(error) }
    }
  }
}
