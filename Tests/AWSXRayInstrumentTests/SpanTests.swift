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

@testable import AWSXRayInstrument
@testable import AWSXRayRecorder

// TODO: test encoding BaggageContext, Events, Links ...

final class SpanTests: XCTestCase {
    func testCreatingSpanWithoutParentSampled() {
        let instrument: TracingInstrument = XRayRecorder(emitter: XRayNoOpEmitter())

        let name: String = UUID().uuidString
        let context = BaggageContext.withoutParentSampled()
        XCTAssertNotNil(context.xRayContext)

        var span: Span = instrument.startSpan(named: name, context: context)

        XCTAssertEqual(name, span.operationName)
        XCTAssertNotEqual(context.xRayContext, span.baggage.xRayContext)
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
        XCTAssertNotEqual(context.xRayContext, span.baggage.xRayContext)
        XCTAssertFalse(span.isRecording)

        span.end()
    }
}
