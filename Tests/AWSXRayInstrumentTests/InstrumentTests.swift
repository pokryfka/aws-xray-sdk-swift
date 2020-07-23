import XCTest

import Baggage
import Instrumentation
import NIOHTTP1
import NIOInstrumentation

@testable import AWSXRayInstrument
@testable import AWSXRayRecorder

final class InstrumentTests: XCTestCase {
    func testExtractingContext() {
        let tracingHeader = "Root=1-5759e988-bd862e3fe1be46a994272793;Sampled=1"
        let headers = HTTPHeaders([
            (AmazonHeaders.traceId, tracingHeader),
        ])
        var baggage = BaggageContext()

        let instrument: TracingInstrument = XRayRecorder(emitter: XRayNoOpEmitter())
        instrument.extract(headers, into: &baggage, using: HTTPHeadersExtractor())

        XCTAssertNotNil(baggage.xRayContext)
        XCTAssertEqual(tracingHeader, baggage.xRayContext?.tracingHeader)
    }

    func testInjectingContext() {
        let tracingHeader = "Root=1-5759e988-bd862e3fe1be46a994272793;Sampled=1"
        var headers = HTTPHeaders()
        let baggage = BaggageContext.withTracingHeader(tracingHeader)
        XCTAssertNotNil(baggage.xRayContext)
        XCTAssertEqual(tracingHeader, baggage.xRayContext?.tracingHeader)

        let instrument: TracingInstrument = XRayRecorder(emitter: XRayNoOpEmitter())
        instrument.inject(baggage, into: &headers, using: HTTPHeadersInjector())

        XCTAssertEqual(tracingHeader, headers[AmazonHeaders.traceId].first)
    }

    func testRecordingOneSpanWithoutParentSampled() {
        let emitter = TestEmitter()
        let instrument: TracingInstrument = XRayRecorder(emitter: emitter)

        XCTAssertEqual(0, emitter.segments.count)

        let name: String = UUID().uuidString
        let context = BaggageContext.withoutParentSampled()
        XCTAssertNotNil(context.xRayContext)

        var span: Span = instrument.startSpan(named: name, context: context, at: nil)

        XCTAssertEqual(name, span.operationName)
        XCTAssertEqual(context.xRayContext, span.baggage.xRayContext)
        XCTAssertTrue(span.isRecording)

        span.end()

        // TODO: instrument does not define any method to flush/wait
        (instrument as? XRayRecorder)?.wait()

        XCTAssertEqual(1, emitter.segments.count)

        // test segment attributes which are internal (and so testable)
        let segment = emitter.segments.first
        XCTAssertEqual(name, segment?.name)
    }

    func testRecordingOneSpanWithoutParentNotSampled() {
        let emitter = TestEmitter()
        let instrument: TracingInstrument = XRayRecorder(emitter: emitter)

        XCTAssertEqual(0, emitter.segments.count)

        let name: String = UUID().uuidString
        let context = BaggageContext.withoutParentNotSampled()
        XCTAssertNotNil(context.xRayContext)

        var span: Span = instrument.startSpan(named: name, context: context, at: nil)

        XCTAssertEqual(name, span.operationName)
        XCTAssertEqual(context.xRayContext, span.baggage.xRayContext)
        XCTAssertFalse(span.isRecording)

        span.end()

        // TODO: instrument does not define any method to flush/wait
        (instrument as? XRayRecorder)?.wait()

        // still empty
        XCTAssertEqual(0, emitter.segments.count)
    }
}
