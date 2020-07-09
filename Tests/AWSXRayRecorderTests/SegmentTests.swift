import Foundation
import XCTest

@testable import AWSXRayRecorder

private typealias Segment = XRayRecorder.Segment
private typealias SegmentError = XRayRecorder.SegmentError

private extension JSONEncoder {
    func encode<T: Encodable>(_ value: T) throws -> String {
        String(decoding: try encode(value), as: UTF8.self)
    }
}

private let jsonEncoder = JSONEncoder()
private let jsonDecoder = JSONDecoder()

final class AWSXRaySegmentTests: XCTestCase {
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

    // MARK: Encoding

    // TODO: use snapshot testing for the JSON output, for now just check it does not throw

    func testSegmentEncodingNoParentNoEnd() {
        let name = UUID().uuidString
        let traceId = XRayRecorder.TraceID()
        let segment = Segment(name: name, traceId: traceId, parentId: nil, subsegment: false)
        let json = XCTAssertNoThrowResult(try jsonEncoder.encode(segment) as String)
    }

    // TODO: check subsegment with no parent, should be parsed as

    func testSegmentEncodingMetadata() {
        let metadata = Segment.Metadata()
        let json = XCTAssertNoThrowResult(try jsonEncoder.encode(metadata) as String)
    }
}
