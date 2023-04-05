import Crypto
import Foundation
import IOUtils
import Logging
import Wrap

public final class Subproject {
  static let LOG: Logger = Logger(label: "Subproject::Subproject")

  public let name: String
  // If nil, then it is a subproject with a directory
  // otherwise it is represented by the Wrapfile
  public var wrap: Wrap?
  // This is the path in $PROJECT_ROOT/subprojects/directory
  public let baseDirectory: String
  // This is where the project was set up (If wrap == nil, it is equal to the baseDirectory)
  public let realDirectory: String?
  private var runDiscover: Bool = false

  public init(name: String, wrap: Wrap?, projectRoot: String) throws {
    self.name = name
    self.wrap = wrap
    if let w = self.wrap {
      self.baseDirectory = "\(projectRoot)/subprojects/\(w.directoryNameAfterSetup)"
    } else {
      self.baseDirectory = "\(projectRoot)/subprojects/\(name)"
    }
    if let w = self.wrap {
      let packagefiles = "\(projectRoot)/subprojects/packagefiles"
      let fm = FileManager.default
      var tempDirectory = fm.temporaryDirectory
      tempDirectory.appendPathComponent("swift-mesonlsp", isDirectory: true)
      let directory = name.data(using: .utf8)!
      let hashedBytes = Data(SHA256.hash(data: directory)).hexStringEncoded()
      tempDirectory.appendPathComponent(hashedBytes, isDirectory: true)
      tempDirectory.appendPathComponent(name + "\(Date().timeIntervalSince1970)", isDirectory: true)
      try fm.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
      self.realDirectory = tempDirectory.absoluteURL.path
      Self.LOG.info("Setting up \(name) in \(tempDirectory.absoluteURL.path)")
      try w.setupDirectory(path: tempDirectory.absoluteURL.path, packagefilesPath: packagefiles)
    } else {
      self.realDirectory = self.baseDirectory
    }
  }

  internal func discoverMore(state: SubprojectState) throws {
    if self.runDiscover { return }
    self.runDiscover = true
    // Assume that subprojects that aren't wrap based
    // don't have any subprojects
    if self.wrap == nil { return }
    guard let realDir = self.realDirectory else { fatalError("Huh?") }
    let subprojects = Path(realDir + "/" + self.wrap!.directoryNameAfterSetup + "/" + "subprojects")
    print(subprojects)
    if !subprojects.exists {
      Self.LOG.info("Subproject \(self.name) has no subprojects")
      return
    }
    let children = try subprojects.children()
    for c in children where c.isFile && c.lastComponent.hasSuffix(".wrap") {
      state.registerSubproject(self, c)
    }
    for c in children where c.isDirectory && c.lastComponent != "packagefiles" {
      state.registerSubproject(self, c)
    }
  }
}
