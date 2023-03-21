public class GitWrap: VcsWrap {
  public private(set) var depth: Int
  public private(set) var pushURL: String
  public private(set) var cloneRecursive: Bool
}
