import XCTest

@testable import AWSXRayRecorder

private typealias Segment = XRayRecorder.Segment
private typealias SegmentError = XRayRecorder.SegmentError

final class RecorderTests: XCTestCase {
    func testRecordingOneSegment() {
        let emitter = TestEmitter()
        let recorder = XRayRecorder(emitter: emitter)

        let segment = recorder.beginSegment(name: UUID().uuidString)
        XCTAssertEqual(0, emitter.segments.count)
        segment.end()

        recorder.wait()

        XCTAssertEqual(1, emitter.segments.count)
    }

    func testRecordingOneSegmentClosure() {
        let emitter = TestEmitter()
        let recorder = XRayRecorder(emitter: emitter)

        recorder.segment(name: UUID().uuidString) { _ in
            XCTAssertEqual(0, emitter.segments.count)
        }

        recorder.wait()

        XCTAssertEqual(1, emitter.segments.count)
    }

    func testRecordingSubsegments() {
        let emitter = TestEmitter()
        let recorder = XRayRecorder(emitter: emitter)

        let segment = recorder.beginSegment(name: UUID().uuidString) // 1

        // subsegments are not counted
        segment.subsegment(name: UUID().uuidString) { _ in }
        segment.subsegment(name: UUID().uuidString) { $0.subsegment(name: UUID().uuidString) { _ in } }
        let subsegmentInProgress = segment.beginSubsegment(name: UUID().uuidString) // not finished

        segment.end()

        // will not be emitted if added after its parent ended
        // TODO: is it expected behaviour? fix or at least signal (throw?)
        _ = segment.beginSubsegment(name: UUID().uuidString) // not finished

        recorder.segment(name: UUID().uuidString) { _ in } // 2
        recorder.beginSegment(name: UUID().uuidString, traceHeader: .init(sampled: .sampled)).end() // 3

        recorder.wait()
        XCTAssertEqual(2, segment.subsegmentsInProgress().count)
        XCTAssertEqual(3, emitter.segments.count)
        emitter.reset()

        subsegmentInProgress.end()
        recorder.wait()
        XCTAssertEqual(1, emitter.segments.count)
    }

    func testTracingHeaderSamplingDecision() {
        let emitter = TestEmitter()
        let recorder = XRayRecorder(emitter: emitter)

        recorder.segment(name: UUID().uuidString, traceHeader: .init(sampled: .sampled)) { _ in }
        recorder.segment(name: UUID().uuidString) { _ in }
        recorder.wait()
        XCTAssertEqual(2, emitter.segments.count)

        emitter.reset()

        recorder.segment(name: UUID().uuidString, traceHeader: .init(sampled: .notSampled)) { _ in }
        recorder.segment(name: UUID().uuidString) { _ in }
        recorder.wait()
        XCTAssertEqual(0, emitter.segments.count)

        emitter.reset()

        recorder.segment(name: UUID().uuidString, traceHeader: .init(sampled: .unknown)) { _ in }
        recorder.segment(name: UUID().uuidString) { _ in }
        recorder.wait()
        XCTAssertEqual(2, emitter.segments.count)

        emitter.reset()

        recorder.segment(name: UUID().uuidString, traceHeader: .init(sampled: .requested)) { _ in }
        recorder.segment(name: UUID().uuidString) { _ in }
        recorder.wait()
        XCTAssertEqual(2, emitter.segments.count)
    }
}
