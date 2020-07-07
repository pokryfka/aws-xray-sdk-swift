import XCTest

@testable import AWSXRayRecorder

final class TimestampTests: XCTestCase {
    func testTimestampAgainstFoundation() {
        let before = Date().timeIntervalSince1970
        let timestamp = Timestamp().secondsSinceEpoch
        let after = Date().timeIntervalSince1970
        XCTAssertLessThanOrEqual(Double(before), timestamp)
        XCTAssertGreaterThanOrEqual(Double(after), timestamp)
    }

    func testTimestampEncoding() {
        let before = Date().timeIntervalSince1970
        let timestamp = Timestamp()
        let after = Date().timeIntervalSince1970
        let encoder = JSONEncoder()
        let string = XCTAssertNoThrowResult(String(decoding: try encoder.encode(timestamp), as: UTF8.self))
        XCTAssertNotNil(string)
        let seconds = Double(string!)
        XCTAssertNotNil(seconds)
        XCTAssertLessThanOrEqual(Double(before), seconds!)
        XCTAssertGreaterThanOrEqual(Double(after), seconds!)
    }
}
