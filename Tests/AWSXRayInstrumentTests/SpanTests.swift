import XCTest

import AWSXRayInstrument
import AWSXRayRecorder
import Instrumentation

final class SpanTests: XCTestCase {
    func testRecordingOneSegment() {
        let recorder = XRayRecorder(emitter: XRayNoOpEmitter())

        let name: String = UUID().uuidString

        // use existing "segment" API, make sure the segment is a proper span
        var span: Span = recorder.beginSegment(name: name)

        XCTAssertEqual(name, span.operationName)
        // TODO: more tests

        span.end()

        // TODO: test end time
    }
}
