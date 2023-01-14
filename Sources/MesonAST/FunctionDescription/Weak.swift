public class Weak<T: AnyObject> {
  public weak var value: T?
  init(value: T) { self.value = value }
}
