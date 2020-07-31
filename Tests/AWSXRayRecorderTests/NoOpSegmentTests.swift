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

@testable import AWSXRayRecorder

private typealias TraceContext = XRayRecorder.TraceContext
private typealias Segment = XRayRecorder.Segment
private typealias NoOpSegment = XRayRecorder.NoOpSegment

final class NoOpSegmentTests: XCTestCase {
    enum TestError: Error {
        case test
    }

    func testCreatingWithDisabledRecorder() {
        let recorder = XRayRecorder(emitter: XRayNoOpEmitter(), config: .init(enabled: false))
        let context = TraceContext(traceId: .init(), sampled: .sampled)

        let segment = recorder.beginSegment(name: UUID().uuidString, context: context)
        XCTAssertFalse(segment.isSampled)
        XCTAssertTrue(segment is NoOpSegment)

        let subsegment = segment.beginSubsegment(name: UUID().uuidString)
        XCTAssertFalse(subsegment.isSampled)
        XCTAssertTrue(subsegment is NoOpSegment)

        XCTAssertEqual(0, segment.subsegmentsInProgress().count)
        subsegment.end()
        XCTAssertEqual(0, segment.subsegmentsInProgress().count)
    }

    func testCreatingWithNotSampledContext() {
        let recorder = XRayRecorder(emitter: XRayNoOpEmitter(), config: .init(enabled: true))
        let context = TraceContext(traceId: .init(), sampled: .notSampled)

        let segment = recorder.beginSegment(name: UUID().uuidString, context: context)
        XCTAssertFalse(segment.isSampled)
        XCTAssertTrue(segment is NoOpSegment)

        let subsegment = segment.beginSubsegment(name: UUID().uuidString)
        XCTAssertFalse(subsegment.isSampled)
        XCTAssertTrue(subsegment is NoOpSegment)

        XCTAssertEqual(0, segment.subsegmentsInProgress().count)
        subsegment.end()
        XCTAssertEqual(0, segment.subsegmentsInProgress().count)
    }

    func testCreatingWithMissingContext() {
        let recorder = XRayRecorder(emitter: XRayNoOpEmitter(), config: .init(enabled: true))

        let segment = recorder.beginSegment(name: UUID().uuidString, baggage: .init())
        XCTAssertFalse(segment.isSampled)
        XCTAssertTrue(segment is NoOpSegment)

        let subsegment = segment.beginSubsegment(name: UUID().uuidString)
        XCTAssertFalse(subsegment.isSampled)
        XCTAssertTrue(subsegment is NoOpSegment)

        XCTAssertEqual(0, segment.subsegmentsInProgress().count)
        subsegment.end()
        XCTAssertEqual(0, segment.subsegmentsInProgress().count)
    }

    func testAddingExceptions() {
        let recorder = XRayRecorder(emitter: XRayNoOpEmitter())
        let context = TraceContext(traceId: .init(), sampled: .notSampled)

        let segment = recorder.beginSegment(name: UUID().uuidString, context: context)
        XCTAssertFalse(segment.isSampled)
        XCTAssertTrue(segment is NoOpSegment)

        segment.addException(message: UUID().uuidString, type: UUID().uuidString)
        segment.addError(TestError.test)
        XCTAssertEqual(0, segment.exceptions.count)
    }

    func testAddingAnnotations() {
        let recorder = XRayRecorder(emitter: XRayNoOpEmitter())
        let context = TraceContext(traceId: .init(), sampled: .notSampled)

        let segment = recorder.beginSegment(name: UUID().uuidString, context: context)
        XCTAssertFalse(segment.isSampled)
        XCTAssertTrue(segment is NoOpSegment)

        segment.setAnnotation(UUID().uuidString, forKey: UUID().uuidString)
        segment.setAnnotation(Bool.random(), forKey: UUID().uuidString)
        segment.setAnnotation(Int.random(in: Int.min ... Int.max), forKey: UUID().uuidString)
        segment.setAnnotation(Double.random(in: -1000 ... 1000), forKey: UUID().uuidString)
        XCTAssertEqual(0, segment.annotations.count)
    }

    func testAddingMetadata() {
        let recorder = XRayRecorder(emitter: XRayNoOpEmitter())
        let context = TraceContext(traceId: .init(), sampled: .notSampled)

        let segment = recorder.beginSegment(name: UUID().uuidString, context: context)
        XCTAssertFalse(segment.isSampled)
        XCTAssertTrue(segment is NoOpSegment)
        segment.setMetadata(["test": "\(UUID().uuidString)"])
        segment.setMetadata("\(UUID().uuidString)", forKey: UUID().uuidString)
        segment.appendMetadata("\(UUID().uuidString)", forKey: UUID().uuidString)
        XCTAssertEqual(0, segment.metadata.count)
    }
}
