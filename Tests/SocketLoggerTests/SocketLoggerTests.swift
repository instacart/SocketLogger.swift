import XCTest
@testable import SocketLogger

class SocketLoggerTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(SocketLogger().text, "Hello, World!")
    }


    static var allTests : [(String, (SocketLoggerTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
