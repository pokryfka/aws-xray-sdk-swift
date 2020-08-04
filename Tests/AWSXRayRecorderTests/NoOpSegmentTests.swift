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

import Logging
import XCTest

@testable import AWSXRayRecorder

private typealias TraceContext = XRayRecorder.TraceContext
private typealias Segment = XRayRecorder.Segment
private typealias NoOpSegment = XRayRecorder.NoOpSegment

final class NoOpSegmentTests: XCTestCase {
    enum TestError: Error {
        case test
    }

    func testRecordingWithDisabledRecorder() {
        let recorder = XRayRecorder(emitter: XRayNoOpEmitter(), config: .init(enabled: false))
        let context = TraceContext(traceId: .init(), sampled: true)

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

    func testRecordingWithNotSampledContext() {
        let recorder = XRayRecorder(emitter: XRayNoOpEmitter(), config: .init(enabled: true))
        let context = TraceContext(traceId: .init(), sampled: false)

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

    func testRecordingWithMissingContext() {
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

    func testRecordingExceptions() {
        let recorder = XRayRecorder(emitter: XRayNoOpEmitter())
        let context = TraceContext(traceId: .init(), sampled: false)

        let segment = recorder.beginSegment(name: UUID().uuidString, context: context)
        XCTAssertFalse(segment.isSampled)
        XCTAssertTrue(segment is NoOpSegment)

        segment.addException(message: UUID().uuidString, type: UUID().uuidString)
        segment.addError(TestError.test)
        XCTAssertEqual(0, segment._test_exceptions.count)
    }

    func testRecordingHTTPRequest() {
        let recorder = XRayRecorder(emitter: XRayNoOpEmitter())
        let context = TraceContext(traceId: .init(), sampled: false)

        let segment = recorder.beginSegment(name: UUID().uuidString, context: context)
        XCTAssertFalse(segment.isSampled)
        XCTAssertTrue(segment is NoOpSegment)

        segment.setHTTPRequest(method: "GET", url: "https://www.example.com/health")
        XCTAssertNil(segment._test_http.request)
        XCTAssertNil(segment._test_http.response)
    }

    func testRecordingHTTPResponse() {
        let recorder = XRayRecorder(emitter: XRayNoOpEmitter())
        let context = TraceContext(traceId: .init(), sampled: false)

        let segment = recorder.beginSegment(name: UUID().uuidString, context: context)
        XCTAssertFalse(segment.isSampled)
        XCTAssertTrue(segment is NoOpSegment)

        segment.setHTTPResponse(status: 200)
        XCTAssertNil(segment._test_http.request)
        XCTAssertNil(segment._test_http.response)
    }

    func testRecordingAnnotations() {
        let recorder = XRayRecorder(emitter: XRayNoOpEmitter())
        let context = TraceContext(traceId: .init(), sampled: false)

        let segment = recorder.beginSegment(name: UUID().uuidString, context: context)
        XCTAssertFalse(segment.isSampled)
        XCTAssertTrue(segment is NoOpSegment)

        segment.setAnnotation(UUID().uuidString, forKey: UUID().uuidString)
        segment.setAnnotation(Bool.random(), forKey: UUID().uuidString)
        segment.setAnnotation(Int.random(in: Int.min ... Int.max), forKey: UUID().uuidString)
        segment.setAnnotation(Double.random(in: -1000 ... 1000), forKey: UUID().uuidString)
        XCTAssertEqual(0, segment._test_annotations.count)
    }

    func testRecordingMetadata() {
        let recorder = XRayRecorder(emitter: XRayNoOpEmitter())
        let context = TraceContext(traceId: .init(), sampled: false)

        let segment = recorder.beginSegment(name: UUID().uuidString, context: context)
        XCTAssertFalse(segment.isSampled)
        XCTAssertTrue(segment is NoOpSegment)

        segment.setMetadata(["test": "\(UUID().uuidString)"])
        segment.setMetadata("\(UUID().uuidString)", forKey: UUID().uuidString)
        segment.appendMetadata("\(UUID().uuidString)", forKey: UUID().uuidString)
        XCTAssertEqual(0, segment._test_metadata.count)
    }

    func testLoggingErrors() {
        let logHandler = TestLogHandler()
        let logger = Logger(label: "test", factory: { _ in logHandler })

        var segment: Segment? = NoOpSegment(id: .init(), name: UUID().uuidString, baggage: .init(), logger: logger)
        XCTAssertFalse(segment!.isSampled)
        XCTAssertTrue(segment is NoOpSegment)

        segment?.end()
        segment?.end()
        segment = nil
        XCTAssertEqual(0, logHandler.errorMessages.count)
    }

    func testFlushing() {
        let emitter = XRayNoOpEmitter()
        let exp = expectation(description: "hasFlushed")
        emitter.flush { error in
            XCTAssertNil(error)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }

    func testShutdown() {
        let emitter = XRayNoOpEmitter()
        let exp = expectation(description: "hasShutdown")
        emitter.shutdown { error in
            XCTAssertNil(error)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
}
