import XCTest

import AWSXRayInstrument
import AWSXRayRecorder
import Baggage
import Dispatch
import Instrumentation

final class InstrumentTests: XCTestCase {
    func testRecordingOneSegment() {
        let emitter = TestEmitter()
        let instrument: TracingInstrument = XRayRecorder(emitter: emitter)

        XCTAssertEqual(0, emitter.segments.count)

        let name: String = UUID().uuidString
        let context = BaggageContext()
        let kind = SpanKind.internal
        let now = DispatchTime.now()

        var span: Span = instrument.startSpan(named: name, context: context, ofKind: kind, at: now)

        // TODO: test attributes

        span.end()

        XCTAssertEqual(1, emitter.segments.count)
    }
}
