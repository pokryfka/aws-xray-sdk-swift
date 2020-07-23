import AnyCodable
import XCTest

@testable import AWSXRayRecorder

private typealias Segment = XRayRecorder.Segment
private typealias SegmentError = XRayRecorder.SegmentError

final class SegmentExceptionTests: XCTestCase {
    func testRecordingExceptionsWithMessageAndType() {
        let segment = Segment(name: UUID().uuidString, traceId: XRayRecorder.TraceID())

        let messageWithType = (UUID().uuidString, UUID().uuidString)
        segment.setException(message: messageWithType.0, type: messageWithType.1)

        let messageWithoutType = UUID().uuidString
        segment.setException(message: messageWithoutType)

        let exceptions = segment.exceptions
        XCTAssertEqual(2, exceptions.count)
        XCTAssertEqual(messageWithType.0, exceptions[0].message)
        XCTAssertEqual(messageWithType.1, exceptions[0].type)
        XCTAssertEqual(messageWithoutType, exceptions[1].message)
        XCTAssertNil(exceptions[1].type)
    }

    func testRecordingErrors() {
        let segment = Segment(name: UUID().uuidString, traceId: XRayRecorder.TraceID())

        enum TestError: Error {
            case test1
            case test2
        }

        segment.setError(TestError.test1)
        segment.setError(TestError.test2)

        let exceptions = segment.exceptions
        XCTAssertEqual(2, exceptions.count)
        XCTAssertEqual("test1", exceptions[0].message) // may be a bit different
        XCTAssertNil(exceptions[0].type)
        XCTAssertEqual("test2", exceptions[1].message) // may be a bit different
        XCTAssertNil(exceptions[1].type)
    }

    func testRecordingHttpErrors() {
        let segment = Segment(name: UUID().uuidString, traceId: XRayRecorder.TraceID())

        let errorWithoutCause = Segment.HTTPError.throttle(cause: nil)
        let errorWithCause = Segment.HTTPError.server(statusCode: 500, cause: .init(message: "Error 500", type: nil))

        segment.setError(errorWithoutCause)
        segment.setError(errorWithCause)

        let exceptions = segment.exceptions
        XCTAssertEqual(1, exceptions.count)
        XCTAssertEqual("Error 500", exceptions.first?.message)
        XCTAssertNil(exceptions.first?.type)
    }
}
