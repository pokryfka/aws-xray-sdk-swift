import XCTest

@testable import AWSXRayRecorder

final class TimestampTests: XCTestCase {
    func testTimestampFromRawValue() {
        let timestamp = Timestamp(rawValue: 1)
        XCTAssertNotNil(timestamp)
        let timestamp2 = Timestamp(rawValue: timestamp!.rawValue)
        XCTAssertNotNil(timestamp2)
        XCTAssertEqual(timestamp, timestamp2)
    }

    func testTimestampFromSeconds() {
        let correctValues: [Double] = [
            1,
            Date().timeIntervalSince1970,
            Date().timeIntervalSince1970 - 1,
            Date().timeIntervalSince1970 + 1,
        ]
        for secondsSinceEpoch in correctValues {
            let timestamp = Timestamp(secondsSinceEpoch: secondsSinceEpoch)
            XCTAssertNotNil(timestamp)
            XCTAssertEqual(secondsSinceEpoch, timestamp?.secondsSinceEpoch)
            let timestamp2 = Timestamp(secondsSinceEpoch: secondsSinceEpoch)
            XCTAssertTrue(timestamp == timestamp2)
        }

        let incorrectValues: [Double] = [
            -1,
            0,
        ]
        for secondsSinceEpoch in incorrectValues {
            let timestamp = Timestamp(secondsSinceEpoch: secondsSinceEpoch)
            XCTAssertNil(timestamp)
        }
    }

    func testTimestampComparison() {
        let now = Date().timeIntervalSince1970
        let timestamp = Timestamp(secondsSinceEpoch: now)
        XCTAssertNotNil(timestamp)
        let timestamp2 = Timestamp(secondsSinceEpoch: now + 1)
        XCTAssertNotNil(timestamp2)
        XCTAssertLessThan(timestamp!, timestamp2!)
        XCTAssertGreaterThan(timestamp2!, timestamp!)
    }

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

    func assert(seconds: Double, after: Date, before: Date, accuracy: UInt = 4) {
        let n = pow(10.0, Double(accuracy))
        let afterSeconds = after.timeIntervalSince1970
        let beforeSeconds = before.timeIntervalSince1970
        XCTAssertLessThanOrEqual(UInt64(beforeSeconds * n), UInt64(seconds * n))
        XCTAssertGreaterThanOrEqual(UInt64(afterSeconds * n), UInt64(seconds * n))
    }
}
