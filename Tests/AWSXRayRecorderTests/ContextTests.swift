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

import Baggage
import Logging
import XCTest

@testable import AWSXRayRecorder

final class ContextTests: XCTestCase {
    private typealias TraceContext = XRayRecorder.TraceContext

    func testMissingContext() {
        let logHandler = TestLogHandler()
        let logger = Logger(label: "test", factory: { _ in logHandler })

        let recorder = XRayRecorder(emitter: XRayNoOpEmitter(), logger: logger)
        let baggage = BaggageContext()
        _ = recorder.beginSegment(name: UUID().uuidString, baggage: baggage)
        XCTAssertEqual(1, logHandler.errorMessages.count)
    }

    func testContextPropagation() {
        enum TestKey: BaggageContextKey {
            typealias Value = String
        }

        let recorder = XRayRecorder(emitter: XRayNoOpEmitter())
        var baggage = BaggageContext()
        let context = XRayContext()
        baggage.xRayContext = context
        let testValue = UUID().uuidString
        baggage[TestKey] = testValue

        let segment = recorder.beginSegment(name: "Segment 1", baggage: baggage)
        XCTAssertNotEqual(context.parentId, segment.id)
        XCTAssertEqual(context.traceId, segment._test_traceId)
        XCTAssertEqual(context.parentId, segment._test_parentId)
        XCTAssertEqual(context.isSampled, segment.isSampled)
        XCTAssertEqual(context.traceId, segment.baggage.xRayContext?.traceId)
        XCTAssertEqual(segment.id, segment.baggage.xRayContext?.parentId)
        XCTAssertEqual(context.isSampled, segment.baggage.xRayContext?.isSampled)
        XCTAssertEqual(testValue, segment.baggage[TestKey])

        let subsegment = recorder.beginSegment(name: "Subsegment 1.1", baggage: segment.baggage)
        XCTAssertNotEqual(segment.id, subsegment.id)
        XCTAssertEqual(context.traceId, subsegment._test_traceId)
        XCTAssertEqual(segment.id, subsegment._test_parentId)
        XCTAssertEqual(context.isSampled, subsegment.isSampled)
        XCTAssertEqual(context.traceId, subsegment.baggage.xRayContext?.traceId)
        XCTAssertEqual(subsegment.id, subsegment.baggage.xRayContext?.parentId)
        XCTAssertEqual(context.isSampled, subsegment.baggage.xRayContext?.isSampled)
        XCTAssertEqual(testValue, subsegment.baggage[TestKey])

        let subsegment2 = segment.beginSubsegment(name: "Subsegment 1.2")
        XCTAssertNotEqual(segment.id, subsegment2.id)
        XCTAssertEqual(context.traceId, subsegment2._test_traceId)
        XCTAssertEqual(segment.id, subsegment2._test_parentId)
        XCTAssertEqual(context.isSampled, subsegment2.isSampled)
        XCTAssertEqual(context.traceId, subsegment.baggage.xRayContext?.traceId)
        XCTAssertEqual(subsegment2.id, subsegment2.baggage.xRayContext?.parentId)
        XCTAssertEqual(context.isSampled, subsegment2.baggage.xRayContext?.isSampled)
        XCTAssertEqual(testValue, subsegment2.baggage[TestKey])
    }
}
