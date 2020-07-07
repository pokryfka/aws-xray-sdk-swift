import NIO
import XCTest

@testable import AWSXRayRecorder

private typealias Segment = XRayRecorder.Segment
private typealias SegmentError = XRayRecorder.SegmentError

final class AWSXRayRecorderTests: XCTestCase {
    func testRecordingOneSegment() {
        let emitter = TestEmitter()
        let recorder = XRayRecorder(emitter: emitter)

        let segmentName = UUID().uuidString
        let segment = recorder.beginSegment(name: segmentName)
        XCTAssertEqual(0, emitter.segments.count)
        segment.end()

        recorder.wait()

        let emittedSegments = emitter.segments
        XCTAssertEqual(1, emittedSegments.count)
        XCTAssertNotNil(emittedSegments.first)
        let theSegment = emittedSegments.first!
        XCTAssertThrowsError(try theSegment.emit()) { error in
            guard case SegmentError.alreadyEmitted = error else {
                XCTFail()
                return
            }
        }
    }

    func testRecordingOneSegmentClosure() {
        let emitter = TestEmitter()
        let recorder = XRayRecorder(emitter: emitter)

        let segmentName = UUID().uuidString
        _ = recorder.segment(name: segmentName) { _ in
            XCTAssertEqual(0, emitter.segments.count)
        }

        recorder.wait()

        let emittedSegments = emitter.segments
        XCTAssertEqual(1, emittedSegments.count)
        XCTAssertNotNil(emittedSegments.first)
        let theSegment = emittedSegments.first!
        XCTAssertThrowsError(try theSegment.emit()) { error in
            guard case SegmentError.alreadyEmitted = error else {
                XCTFail()
                return
            }
        }
    }
}
