//===----------------------------------------------------------------------===//
//
// This source file is part of the aws-xray-sdk-swift open source project
//
// Copyright (c) 2020 pokryfka and the aws-xray-sdk-swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import XCTest

import Baggage
import Instrumentation
import NIOHTTP1
import NIOInstrumentation
import TracingInstrumentation

@testable import AWSXRayInstrument
@testable import AWSXRayRecorder

final class InstrumentTests: XCTestCase {
    private enum AmazonHeaders {
        static let traceId = "X-Amzn-Trace-Id"
    }

    private typealias TracingInstrument = TracingInstrumentation.TracingInstrument

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

        var span: Span = instrument.startSpan(named: name, context: context)

        XCTAssertEqual(name, span.operationName)
        XCTAssertNotEqual(context.xRayContext, span.context.xRayContext)
        XCTAssertTrue(span.isRecording)

        span.end()

        instrument.forceFlush()
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

        var span: Span = instrument.startSpan(named: name, context: context)

        XCTAssertEqual(name, span.operationName)
        XCTAssertNotEqual(context.xRayContext, span.context.xRayContext)
        XCTAssertFalse(span.isRecording)

        span.end()

        instrument.forceFlush()
        // still empty
        XCTAssertEqual(0, emitter.segments.count)
    }
}
