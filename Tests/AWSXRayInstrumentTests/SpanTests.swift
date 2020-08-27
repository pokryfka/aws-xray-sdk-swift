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

final class SpanTests: XCTestCase {
    private typealias TracingInstrument = TracingInstrumentation.TracingInstrument
    private typealias AnnotationValue = XRayRecorder.Segment.AnnotationValue

    private func createSpan(name: String = UUID().uuidString,
                            context: BaggageContext = .withoutParentSampled()) -> Span
    {
        let instrument: TracingInstrument = XRayRecorder(emitter: XRayNoOpEmitter())
        return instrument.startSpan(named: name, context: context)
    }

    // MARK: Context

    func testCreatingSpanWithContextWithoutParentSampled() {
        let name: String = UUID().uuidString
        let context = BaggageContext.withoutParentSampled()
        XCTAssertNotNil(context.xRayContext)

        var span: Span = createSpan(name: name, context: context)

        XCTAssertNotEqual(context.xRayContext, span.context.xRayContext)
        XCTAssertTrue(span.isRecording)

        span.end()
    }

    func testCreatingSpanWithContextWithoutParentNotSampled() {
        let name: String = UUID().uuidString
        let context = BaggageContext.withoutParentNotSampled()
        XCTAssertNotNil(context.xRayContext)

        var span: Span = createSpan(name: name, context: context)

        XCTAssertNotEqual(context.xRayContext, span.context.xRayContext)
        XCTAssertFalse(span.isRecording)

        span.end()
    }

    func testCreatingSpanWithoutContext() {
        let name: String = UUID().uuidString
        let context = BaggageContext() // empty
        XCTAssertNil(context.xRayContext)

        // should report error by default and create not sampled context
        var span: Span = createSpan(name: name, context: context)

        XCTAssertNotEqual(context.xRayContext, span.context.xRayContext)
        XCTAssertFalse(span.isRecording)

        span.end()
    }

    // MARK: Status

    func testSettingOkStatus() {
        var span = createSpan()

        span.setStatus(.init(canonicalCode: .ok))

        let segment = try! XCTUnwrap(span as? XRayRecorder.Segment)
        XCTAssertEqual(0, segment._test_annotations.count)
        XCTAssertEqual(0, segment._test_exceptions.count)
    }

    func testSettingNotFoundStatus() {
        var span = createSpan()

        span.setStatus(.init(canonicalCode: .notFound, message: "test"))

        let segment = try! XCTUnwrap(span as? XRayRecorder.Segment)
        XCTAssertEqual(1, segment._test_annotations.count)
        XCTAssertEqual(AnnotationValue.string("notFound: test"), segment._test_annotations["status"])
        XCTAssertEqual(1, segment._test_exceptions.count)
    }

    // MARK: Attributes

    func testSettingStringAttribute() {
        var span = createSpan()

        span.attributes["string"] = "abc"
        XCTAssertNil(span.attributes["string"])
        XCTAssertTrue(span.attributes.isEmpty)

        let segment = try! XCTUnwrap(span as? XRayRecorder.Segment)
        XCTAssertEqual(1, segment._test_annotations.count)
        XCTAssertEqual(AnnotationValue.string("abc"), segment._test_annotations["string"])
    }

    func testSettingBooleanAttribute() {
        var span = createSpan()

        span.attributes["bool"] = true
        XCTAssertNil(span.attributes["bool"])
        XCTAssertTrue(span.attributes.isEmpty)

        let segment = try! XCTUnwrap(span as? XRayRecorder.Segment)
        XCTAssertEqual(1, segment._test_annotations.count)
        XCTAssertEqual(AnnotationValue.bool(true), segment._test_annotations["bool"])
    }

    func testSettingIntegerAttribute() {
        var span = createSpan()

        span.attributes["int"] = 42
        XCTAssertNil(span.attributes["int"])
        XCTAssertTrue(span.attributes.isEmpty)

        let segment = try! XCTUnwrap(span as? XRayRecorder.Segment)
        XCTAssertEqual(1, segment._test_annotations.count)
        XCTAssertEqual(AnnotationValue.integer(42), segment._test_annotations["int"])
    }

    func testSettingDoubleAttribute() {
        var span = createSpan()

        span.attributes["double"] = 3.14
        XCTAssertNil(span.attributes["double"])
        XCTAssertTrue(span.attributes.isEmpty)

        let segment = try! XCTUnwrap(span as? XRayRecorder.Segment)
        XCTAssertEqual(1, segment._test_annotations.count)
        XCTAssertEqual(AnnotationValue.double(3.14), segment._test_annotations["double"])
    }

    func testSettingArrayAttribute() {
        var span = createSpan()

        span.attributes["array"] = [1, 2]
        XCTAssertNil(span.attributes["array"])
        XCTAssertTrue(span.attributes.isEmpty)

        // not recorded at the moment
        let segment = try! XCTUnwrap(span as? XRayRecorder.Segment)
        XCTAssertEqual(0, segment._test_annotations.count)
        XCTAssertTrue(segment._test_annotations.isEmpty)
        XCTAssertTrue(segment._test_metadata.isEmpty)
    }

    func testSettingAttributesObject() {
        var span = createSpan()

        let attributes: SpanAttributes = [
            "string": "abc",
            "bool": false,
            "int": 137,
            "double": 3.14,
        ]
        span.attributes = attributes
        XCTAssertTrue(span.attributes.isEmpty)

        let segment = try! XCTUnwrap(span as? XRayRecorder.Segment)
        XCTAssertEqual(4, segment._test_annotations.count)
        XCTAssertEqual(AnnotationValue.string("abc"), segment._test_annotations["string"])
        XCTAssertEqual(AnnotationValue.bool(false), segment._test_annotations["bool"])
        XCTAssertEqual(AnnotationValue.integer(137), segment._test_annotations["int"])
        XCTAssertEqual(AnnotationValue.double(3.14), segment._test_annotations["double"])
    }

    // MARK: Links

    func testAddingLinks() {
        var span = createSpan()

        let other = createSpan()
        span.addLink(other)

        // nothing is recorded at the moment
        let segment = try! XCTUnwrap(span as? XRayRecorder.Segment)
        XCTAssertTrue(segment._test_annotations.isEmpty)
        XCTAssertTrue(segment._test_metadata.isEmpty)
    }

    // MARK: Events

    func testAddingEvents() {
        var span = createSpan()

        span.addEvent(.init(name: "Event 1"))
        span.addEvent(.init(name: "Event 2"))

        // stored as appendable metadata object
        let segment = try! XCTUnwrap(span as? XRayRecorder.Segment)
        XCTAssertTrue(segment._test_annotations.isEmpty)
        XCTAssertEqual(1, segment._test_metadata.count)
        // TODO: this will get simplified #61
        let events = try! XCTUnwrap((segment._test_metadata["events"])?.value as? [Any])
        XCTAssertEqual(2, events.count)
    }
}
