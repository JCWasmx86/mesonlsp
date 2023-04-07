import Foundation
import Wrap

public class WrapBasedSubproject: Subproject {
  private let wrap: Wrap
  private let destDir: String

  public init(
    wrapName: String,
    wrap: Wrap,
    packagefiles: String,
    parent: Subproject?,
    destDir: String
  ) throws {
    self.wrap = wrap
    self.destDir = destDir
    try super.init(name: wrapName, parent: parent)
    try self.wrap.setupDirectory(path: self.destDir, packagefilesPath: packagefiles)
  }

  public override var description: String {
    return "WrapSubproject(\(name),\(realpath),\(self.wrap.directoryNameAfterSetup))"
  }
}
