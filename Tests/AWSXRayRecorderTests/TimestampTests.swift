import XCTest

@testable import AWSXRayRecorder

import struct Foundation.Data

final class TimestampTests: XCTestCase {
    func testTimestampAgainstFoundation() {
        let before = Date().timeIntervalSince1970
        let timestamp = Timestamp().secondsSinceEpoch
        let after = Date().timeIntervalSince1970
        XCTAssertLessThanOrEqual(Double(before), timestamp)
        XCTAssertGreaterThanOrEqual(Double(after), timestamp)
    }
}
