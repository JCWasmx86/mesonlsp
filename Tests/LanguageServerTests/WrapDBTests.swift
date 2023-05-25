import Wrap
import XCTest

class WrapDBTests: XCTestCase {
  func testInitializeWrapDB() async {
    do { try await WrapDB.INSTANCE.initDB() } catch { XCTAssertNoThrow(error) }
    XCTAssertTrue(WrapDB.INSTANCE.containsWrap("zstd"))
  }
  func testDownloading() async {
    do { try await WrapDB.INSTANCE.initDB() } catch { XCTAssertNoThrow(error) }
    do { XCTAssertNotNil(try WrapDB.INSTANCE.downloadWrapToString("zstd")) } catch {
      XCTAssertNoThrow(error)
    }
  }
}
