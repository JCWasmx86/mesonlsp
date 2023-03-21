public class VcsWrap: Wrap {
  public private(set) var url: String?
  public private(set) var revision: String?

  internal init(
    directory: String?,
    patchURL: String?,
    patchFallbackURL: String?,
    patchFilename: String?,
    patchHash: String?,
    patchDirectory: String?,
    diffFiles: [String]?,
    url: String?,
    revision: String?
  ) {
    self.url = url
    self.revision = revision
    super.init(
      directory: directory,
      patchURL: patchURL,
      patchFallbackURL: patchFallbackURL,
      patchFilename: patchFilename,
      patchHash: patchHash,
      patchDirectory: patchDirectory,
      diffFiles: diffFiles
    )
  }
}
