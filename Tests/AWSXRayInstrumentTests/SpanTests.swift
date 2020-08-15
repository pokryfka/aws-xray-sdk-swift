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
import TracingInstrumentation

@testable import AWSXRayInstrument
@testable import AWSXRayRecorder

// TODO: test encoding BaggageContext, Events, Links ...

final class SpanTests: XCTestCase {
    private typealias TracingInstrument = TracingInstrumentation.TracingInstrument
    private typealias AnnotationValue = XRayRecorder.Segment.AnnotationValue

    func testCreatingSpanWithoutParentSampled() {
        let instrument: TracingInstrument = XRayRecorder(emitter: XRayNoOpEmitter())

        let name: String = UUID().uuidString
        let context = BaggageContext.withoutParentSampled()
        XCTAssertNotNil(context.xRayContext)

        var span: Span = instrument.startSpan(named: name, context: context)

        XCTAssertEqual(name, span.operationName)
        XCTAssertNotEqual(context.xRayContext, span.context.xRayContext)
        XCTAssertTrue(span.isRecording)

        span.end()
    }

    func testCreatingSpanWithoutParentNotSampled() {
        let instrument: TracingInstrument = XRayRecorder(emitter: XRayNoOpEmitter())

        let name: String = UUID().uuidString
        let context = BaggageContext.withoutParentNotSampled()
        XCTAssertNotNil(context.xRayContext)

        var span: Span = instrument.startSpan(named: name, context: context)

        XCTAssertEqual(name, span.operationName)
        XCTAssertNotEqual(context.xRayContext, span.context.xRayContext)
        XCTAssertFalse(span.isRecording)

        span.end()
    }

    func testCreatingAttributes() {
        let instrument: TracingInstrument = XRayRecorder(emitter: XRayNoOpEmitter())

        var span: Span = instrument.startSpan(named: UUID().uuidString, context: BaggageContext.withoutParentSampled())
        span.attributes["string"] = "abc"
        XCTAssertNil(span.attributes["string"])
        span.attributes["bool"] = true
        XCTAssertNil(span.attributes["bool"])
        span.attributes["int"] = 42
        XCTAssertNil(span.attributes["int"])
        span.attributes["double"] = 3.14
        XCTAssertNil(span.attributes["double"])

        XCTAssertTrue(span.attributes.isEmpty)

        let segment = try! XCTUnwrap(span as? XRayRecorder.Segment)
        XCTAssertEqual(4, segment._test_annotations.count)
        XCTAssertEqual(AnnotationValue.string("abc"), segment._test_annotations["string"])
        XCTAssertEqual(AnnotationValue.bool(true), segment._test_annotations["bool"])
        XCTAssertEqual(AnnotationValue.integer(42), segment._test_annotations["int"])
        XCTAssertEqual(AnnotationValue.double(3.14), segment._test_annotations["double"])
    }
}
