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
        // encoding timestamp fails on Linux with "Top-level Timestamp encoded as number JSON fragment."
        let value = ["timestmap": timestamp]
        let after = Date()
        let encoder = JSONEncoder()
        let string = String(decoding: try! encoder.encode(value), as: UTF8.self)
        let parsedValue = string.dropFirst("{\"timestmap\":".count).dropLast()
        let seconds = Double(parsedValue)
        XCTAssertNotNil(seconds)
        assert(seconds: seconds!, after: after, before: before)
    }

    func assert(timestamp: Timestamp, after: Date, before: Date) {
        assert(seconds: timestamp.secondsSinceEpoch, after: after, before: before)
    }

    func assert(seconds: Double, after: Date, before: Date, decimals: UInt = 4) {
        let n = pow(10.0, Double(decimals))
        let afterSeconds = after.timeIntervalSince1970
        let beforeSeconds = before.timeIntervalSince1970
        XCTAssertLessThanOrEqual(UInt64(beforeSeconds * n), UInt64(seconds * n))
        XCTAssertGreaterThanOrEqual(UInt64(afterSeconds * n), UInt64(seconds * n))
    }
}
