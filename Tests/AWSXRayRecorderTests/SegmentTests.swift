import Foundation
import XCTest

@testable import AWSXRayRecorder

private typealias Segment = XRayRecorder.Segment
private typealias SegmentError = XRayRecorder.SegmentError

extension Segment {
    fileprivate static let idLength: Int = 16
    fileprivate static let idInvalidCharacters = CharacterSet(charactersIn: "abcdef0123456789").inverted
}

final class AWSXRaySegmentTests: XCTestCase {
    func testSegmentRandomId() {
        let numTests = 1000
        var values = Set<String>()
        for _ in 0 ..< numTests {
            let segmendId = XRayRecorder.Segment.generateId()
            XCTAssertEqual(segmendId.count, Segment.idLength)
            XCTAssertNil(segmendId.rangeOfCharacter(from: Segment.idInvalidCharacters))
            values.insert(segmendId)
        }
        XCTAssertEqual(values.count, numTests)
    }

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

    // TODO: annotations and metadata tests

    // TODO: subsegments tests
}
