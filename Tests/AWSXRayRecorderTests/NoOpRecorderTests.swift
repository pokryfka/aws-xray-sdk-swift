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
import XCTest

@testable import AWSXRayRecorder

final class NoOpRecorderTests: XCTestCase {
    func testCreatingSegments() {
        let recorder = XRayNoOpRecorder()
        XCTAssertTrue(recorder.beginSegment(name: UUID().uuidString, context: .init()) is XRayRecorder.NoOpSegment)
        XCTAssertFalse(recorder.beginSegment(name: UUID().uuidString, context: .init()).isSampled)
        XCTAssertTrue(recorder.beginSegment(name: UUID().uuidString, baggage: .init()) is XRayRecorder.NoOpSegment)
        XCTAssertFalse(recorder.beginSegment(name: UUID().uuidString, baggage: .init()).isSampled)
    }

    func testFlushing() {
        let recorder = XRayNoOpRecorder()
        let exp = expectation(description: "hasFlushed")
        recorder.wait { error in
            XCTAssertNil(error)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }

    func testShutdown() {
        let recorder = XRayNoOpRecorder()
        let exp = expectation(description: "hasShutdown")
        recorder.shutdown { error in
            XCTAssertNil(error)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }

    func testContextPropagation() {
        enum TestKey: BaggageContextKey {
            typealias Value = String
        }

        let recorder = XRayNoOpRecorder()
        var baggage = BaggageContext()
        let context = XRayContext()
        baggage.xRayContext = context
        let testValue = UUID().uuidString
        baggage[TestKey] = testValue

        let segment = recorder.beginSegment(name: "Segment 1", baggage: baggage)
        XCTAssertNotEqual(context.parentId, segment.id)
        XCTAssertEqual(context.traceId, segment._test_traceId)
        XCTAssertEqual(context.parentId, segment._test_parentId)
        XCTAssertFalse(segment.isSampled)
        XCTAssertEqual(context.traceId, segment.baggage.xRayContext?.traceId)
        XCTAssertEqual(segment.id, segment.baggage.xRayContext?.parentId)
        XCTAssertEqual(context.isSampled, segment.baggage.xRayContext?.isSampled)
        XCTAssertEqual(testValue, segment.baggage[TestKey])

        let subsegment = recorder.beginSegment(name: "Subsegment 1.1", baggage: segment.baggage)
        XCTAssertNotEqual(segment.id, subsegment.id)
        XCTAssertEqual(context.traceId, subsegment._test_traceId)
        XCTAssertEqual(segment.id, subsegment._test_parentId)
        XCTAssertFalse(subsegment.isSampled)
        XCTAssertEqual(context.traceId, subsegment.baggage.xRayContext?.traceId)
        XCTAssertEqual(subsegment.id, subsegment.baggage.xRayContext?.parentId)
        XCTAssertEqual(context.isSampled, subsegment.baggage.xRayContext?.isSampled)
        XCTAssertEqual(testValue, subsegment.baggage[TestKey])

        let subsegment2 = segment.beginSubsegment(name: "Subsegment 1.2")
        XCTAssertNotEqual(segment.id, subsegment2.id)
        XCTAssertEqual(context.traceId, subsegment2._test_traceId)
        XCTAssertEqual(segment.id, subsegment2._test_parentId)
        XCTAssertFalse(subsegment2.isSampled)
        XCTAssertEqual(context.traceId, subsegment.baggage.xRayContext?.traceId)
        XCTAssertEqual(subsegment2.id, subsegment2.baggage.xRayContext?.parentId)
        XCTAssertEqual(context.isSampled, subsegment2.baggage.xRayContext?.isSampled)
        XCTAssertEqual(testValue, subsegment2.baggage[TestKey])
    }
}
