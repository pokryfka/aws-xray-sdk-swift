import XCTest

import AWSXRayInstrument
import AWSXRayRecorder
import Baggage
import Instrumentation

final class SpanTests: XCTestCase {
    func testCreatingSegment() {
        let instrument: TracingInstrument = XRayRecorder(emitter: XRayNoOpEmitter())

        let name: String = UUID().uuidString
        let context = BaggageContext()

        var span: Span = instrument.startSpan(named: name, context: context)

        XCTAssertEqual(name, span.operationName)
        // TODO: more tests

        span.end()

        // TODO: test end time
    }
}
