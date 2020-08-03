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
private typealias SegmentError = XRayRecorder.SegmentError

final class RecorderTests: XCTestCase {
    func testRecordingOneSegment() {
        let emitter = TestEmitter()
        let recorder = XRayRecorder(emitter: emitter)

        let segment = recorder.beginSegment(name: UUID().uuidString, context: .init())
        XCTAssertEqual(0, emitter.segments.count)
        segment.end()

        recorder.wait()

        XCTAssertEqual(1, emitter.segments.count)
    }

    func testRecordingOneSegmentClosure() {
        let emitter = TestEmitter()
        let recorder = XRayRecorder(emitter: emitter)

        recorder.segment(name: UUID().uuidString, context: .init()) { _ in
            XCTAssertEqual(0, emitter.segments.count)
        }

        recorder.wait()

        XCTAssertEqual(1, emitter.segments.count)
    }

    func testRecordingSubsegments() {
        let emitter = TestEmitter()
        let recorder = XRayRecorder(emitter: emitter)

        let segment = recorder.beginSegment(name: UUID().uuidString, context: .init()) // 1

        // subsegments are not counted
        segment.subsegment(name: UUID().uuidString) { _ in }
        segment.subsegment(name: UUID().uuidString) { $0.subsegment(name: UUID().uuidString) { _ in } }
        let subsegmentInProgress = segment.beginSubsegment(name: UUID().uuidString) // not finished

        segment.end()

        // will not be emitted if added after its parent ended
        // TODO: is it expected behaviour? fix or at least signal (throw?)
        _ = segment.beginSubsegment(name: UUID().uuidString) // not finished

        recorder.segment(name: UUID().uuidString, context: .init()) { _ in } // 2
        recorder.beginSegment(name: UUID().uuidString, context: .init(sampled: true)).end() // 3

        recorder.wait()
        XCTAssertEqual(2, segment.subsegmentsInProgress().count)
        XCTAssertEqual(3, emitter.segments.count)
        emitter.reset()

        subsegmentInProgress.end()
        recorder.wait()
        XCTAssertEqual(1, emitter.segments.count)
    }

    func testTracingHeaderSamplingDecision() {
        let emitter = TestEmitter()
        let recorder = XRayRecorder(emitter: emitter)

        let contextSampled = TraceContext(sampled: true)
        recorder.segment(name: UUID().uuidString, context: contextSampled) { _ in }
        recorder.segment(name: UUID().uuidString, context: contextSampled) { _ in }
        recorder.wait()
        XCTAssertEqual(2, emitter.segments.count)

        emitter.reset()

        let contextNotSampled = TraceContext(sampled: false)
        recorder.segment(name: UUID().uuidString, context: contextNotSampled) { _ in }
        recorder.segment(name: UUID().uuidString, context: contextNotSampled) { _ in }
        recorder.wait()
        XCTAssertEqual(0, emitter.segments.count)

        emitter.reset()

        let contextUnkownSampling = TraceContext(traceId: .init(), parentId: nil, sampled: .unknown)
        recorder.segment(name: UUID().uuidString, context: contextUnkownSampling) { _ in }
        recorder.segment(name: UUID().uuidString, context: contextUnkownSampling) { _ in }
        recorder.wait()
        XCTAssertEqual(0, emitter.segments.count)

        emitter.reset()

        let contextRequestedSampling = TraceContext(traceId: .init(), parentId: nil, sampled: .requested)
        recorder.segment(name: UUID().uuidString, context: contextRequestedSampling) { _ in }
        recorder.segment(name: UUID().uuidString, context: contextRequestedSampling) { _ in }
        recorder.wait()
        XCTAssertEqual(0, emitter.segments.count)
    }
}
