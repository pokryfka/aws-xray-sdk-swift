import XCTest

@testable import AWSXRayRecorder

final class TimestampTests: XCTestCase {
    func testTimestampAgainstFoundation() {
        let before = Date()
        let timestamp = Timestamp()
        let after = Date()
        assert(timestamp: timestamp, after: after, before: before)
    }

    func testTimestampEncoding() {
        let before = Date()
        let timestamp = Timestamp()
        let after = Date()
        let encoder = JSONEncoder()
        let string = XCTAssertNoThrowResult(String(decoding: try encoder.encode(timestamp), as: UTF8.self))
        XCTAssertNotNil(string)
        let seconds = Double(string!)
        XCTAssertNotNil(seconds)
        assert(seconds: seconds, after: after, before: before)
    }

    func assert(timestamp: Timestamp, after: Date, before: Date) {
        assert(seconds: timestamp.secondsSinceEpoch, after: after, before: before)
    }

    func assert(seconds: Double?, after: Date, before: Date, decimals: UInt = 4) {
        let n = pow(10.0, Double(decimals))
        let seconds = seconds ?? 0
        let afterSeconds = after.timeIntervalSince1970
        let beforeSeconds = before.timeIntervalSince1970
        XCTAssertLessThanOrEqual(UInt64(beforeSeconds * n), UInt64(seconds * n))
        XCTAssertGreaterThanOrEqual(UInt64(afterSeconds * n), UInt64(seconds * n))
    }
}
