public class GitWrap: VcsWrap {
  public private(set) var depth: Int
  public private(set) var pushURL: String?
  public private(set) var cloneRecursive: Bool?

  internal init(
    directory: String?,
    patchURL: String?,
    patchFallbackURL: String?,
    patchFilename: String?,
    patchHash: String?,
    patchDirectory: String?,
    diffFiles: [String],
    url: String?,
    revision: String?,
    depth: Int,
    pushURL: String?,
    cloneRecursive: Bool
  ) {
    self.depth = depth
    self.pushURL = pushURL
    self.cloneRecursive = cloneRecursive
    super.init(
      directory: directory,
      patchURL: patchURL,
      patchFallbackURL: patchFallbackURL,
      patchFilename: patchFilename,
      patchHash: patchHash,
      patchDirectory: patchDirectory,
      diffFiles: diffFiles,
      url: url,
      revision: revision
    )
  }
}
