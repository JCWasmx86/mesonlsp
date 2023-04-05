import Crypto
import Foundation
import Logging
import Wrap

public class Subproject {
  static let LOG: Logger = Logger(label: "Subproject::Subproject")

  public let name: String
  // If nil, then it is a subproject with a directory
  // otherwise it is represented by the Wrapfile
  public var wrap: Wrap?
  // This is the path in $PROJECT_ROOT/subprojects/directory
  public let baseDirectory: String
  // This is where the project was set up (nil, if wrap == nil)
  public let realDirectory: String?

  public init(name: String, wrap: Wrap?, projectRoot: String, realDirectory: String?) throws {
    self.name = name
    self.wrap = wrap
    if let w = self.wrap {
      guard let wdir = w.directory else { fatalError("TODO") }
      self.baseDirectory = "\(projectRoot)/subprojects/\(wdir)"
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
      self.realDirectory = tempDirectory.absoluteString
      Self.LOG.info("Setting up \(name) in \(tempDirectory.absoluteString)")
      try w.setupDirectory(path: tempDirectory.absoluteString, packagefilesPath: packagefiles)
    } else {
      self.realDirectory = nil
    }
  }
}
