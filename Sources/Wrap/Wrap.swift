public class Wrap {
  public private(set) var directory: String?
  public private(set) var patchURL: String?
  public private(set) var patchFallbackURL: String?
  public private(set) var patchFilename: String?
  public private(set) var patchHash: String?
  public private(set) var patchDirectory: String?
  public private(set) var diffFiles: [String]?
  public private(set) var provides: Provides = Provides()

  internal init(
    directory: String?,
    patchURL: String?,
    patchFallbackURL: String?,
    patchFilename: String?,
    patchHash: String?,
    patchDirectory: String?,
    diffFiles: [String]?
  ) {
    self.directory = directory
    self.patchURL = patchURL
    self.patchFallbackURL = patchFallbackURL
    self.patchFilename = patchFilename
    self.patchHash = patchHash
    self.patchDirectory = patchDirectory
    self.diffFiles = diffFiles
  }

  internal func applyProvides(_ provides: Provides) { self.provides = provides }
}
