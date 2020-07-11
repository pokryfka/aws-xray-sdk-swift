import Foundation
import XCTest

@testable import AWSXRayRecorder

private typealias Segment = XRayRecorder.Segment
private typealias SegmentError = XRayRecorder.SegmentError

final class SegmentTests: XCTestCase {
    func testSegmentInvalidId() {
        for string in ["", "1", "1234567890", "123456789012345z"] {
            XCTAssertThrowsError(try Segment.validateId(string)) { error in
                if case SegmentError.invalidID(let invalidValue) = error {
                    XCTAssertEqual(invalidValue, string)
                } else {
                    XCTFail()
                }
            }
        }
    }
}
