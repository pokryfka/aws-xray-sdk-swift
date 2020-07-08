import XCTest

// XCTAssertNoThrow does not return the result
func XCTAssertNoThrowResult<T>(_ expression: @autoclosure () throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) -> T? {
    do {
        return try expression()
    } catch {
        XCTFail(message(), file: file, line: line)
        return nil
    }
}
