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

private typealias Segment = XRayRecorder.Segment
private typealias SegmentError = XRayRecorder.SegmentError

final class SegmentExceptionTests: XCTestCase {
    func testRecordingExceptions() {
        let segment = Segment(id: .init(), name: UUID().uuidString, context: .init())
        XCTAssertEqual(0, segment._test_exceptions.count)

        let messageWithType = (UUID().uuidString, UUID().uuidString)
        segment.addException(message: messageWithType.0, type: messageWithType.1)
        XCTAssertEqual(1, segment._test_exceptions.count)

        let messageWithoutType = UUID().uuidString
        segment.addException(message: messageWithoutType)
        XCTAssertEqual(2, segment._test_exceptions.count)

        let exceptions = segment._test_exceptions
        XCTAssertEqual(messageWithType.0, exceptions[0].message)
        XCTAssertEqual(messageWithType.1, exceptions[0].type)
        XCTAssertEqual(messageWithoutType, exceptions[1].message)
        XCTAssertNil(exceptions[1].type)
    }

    func testRecordingErrors() {
        let segment = Segment(id: .init(), name: UUID().uuidString, context: .init())
        XCTAssertEqual(0, segment._test_exceptions.count)

        enum TestError: Error {
            case test1
            case test2
        }

        segment.addError(TestError.test1)
        XCTAssertEqual(1, segment._test_exceptions.count)
        segment.addError(TestError.test2)
        XCTAssertEqual(2, segment._test_exceptions.count)

        let exceptions = segment._test_exceptions
        XCTAssertEqual("test1", exceptions[0].message) // may be a bit different
        XCTAssertNil(exceptions[0].type)
        XCTAssertEqual("test2", exceptions[1].message) // may be a bit different
        XCTAssertNil(exceptions[1].type)
    }

    func testRecordingThrownErrors() {
        let emitter = TestEmitter()
        let recorder = XRayRecorder(emitter: emitter)

        enum TestError: Error {
            case test
        }

        XCTAssertNil(emitter.segments.first)
        do {
            try recorder.segment(name: UUID().uuidString, context: .init()) { _ in
                throw TestError.test
            }
        } catch {}
        recorder.wait()
        XCTAssertEqual(1, emitter.segments.first?._test_exceptions.count)

        emitter.reset()
        XCTAssertNil(emitter.segments.first)
        do {
            var baggage = BaggageContext()
            baggage.xRayContext = .init()
            try recorder.segment(name: UUID().uuidString, baggage: baggage) { _ in
                throw TestError.test
            }
        } catch {}
        recorder.wait()
        XCTAssertEqual(1, emitter.segments.first?._test_exceptions.count)

        emitter.reset()
        recorder.segment(name: UUID().uuidString, context: .init()) { segment in
            try? segment.subsegment(name: UUID().uuidString) { _ in
                throw TestError.test
            }
            XCTAssertEqual(1, segment._test_subsegments.first?._test_exceptions.count)
        }
    }

    func testRecordingFailures() {
        let emitter = TestEmitter()
        let recorder = XRayRecorder(emitter: emitter)

        enum TestError: Error {
            case test
        }

        XCTAssertNil(emitter.segments.first)
        _ = recorder.segment(name: UUID().uuidString, context: .init()) { _ in
            Result<Void, TestError>.failure(TestError.test)
        }
        recorder.wait()
        XCTAssertEqual(1, emitter.segments.first?._test_exceptions.count)

        emitter.reset()
        XCTAssertNil(emitter.segments.first)
        var baggage = BaggageContext()
        baggage.xRayContext = .init()
        _ = recorder.segment(name: UUID().uuidString, baggage: baggage) { _ in
            Result<Void, TestError>.failure(TestError.test)
        }
        recorder.wait()
        XCTAssertEqual(1, emitter.segments.first?._test_exceptions.count)

        emitter.reset()
        recorder.segment(name: UUID().uuidString, context: .init()) { segment in
            _ = segment.subsegment(name: UUID().uuidString) { _ in
                Result<Void, TestError>.failure(TestError.test)
            }
            XCTAssertEqual(1, segment._test_subsegments.first?._test_exceptions.count)
        }
    }

    func testPropagatingErrorsToParent() {
        enum ExampleError: Error {
            case test
        }

        let recorder = XRayRecorder(emitter: XRayNoOpEmitter())
        recorder.segment(name: "Segment 2", context: .init()) { segment in
            XCTAssertEqual(0, segment._test_exceptions.count)

            try? segment.subsegment(name: "Subsegment 2.1") { segment in
                XCTAssertEqual(0, segment._test_exceptions.count)

                _ = segment.subsegment(name: "Subsegment 2.1.1 with Result") { _ -> String in
                    usleep(100_000)
                    return "Result"
                }
                try segment.subsegment(name: "Subsegment 2.1.2 with Error") { _ in
                    usleep(200_000)
                    throw ExampleError.test
                }

                XCTAssertEqual(1, segment._test_exceptions.count)
            }

            // note `try?`
            XCTAssertEqual(0, segment._test_exceptions.count)
        }
    }
}

import NIO

final class SegmentExceptionNIOTests: XCTestCase {
    func testRecordingTaskError() {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        defer {
            XCTAssertNoThrow(try eventLoopGroup.syncShutdownGracefully())
        }

        enum TestError: Error {
            case test
        }

        func doWork(on eventLoop: EventLoop) -> EventLoopFuture<Void> {
            eventLoop.submit { throw TestError.test }.map { _ in }
        }

        let emitter = TestEmitter()
        let recorder = XRayRecorder(emitter: emitter)

        let eventLoop = eventLoopGroup.next()

        try! recorder.segment(name: UUID().uuidString, context: .init()) {
            doWork(on: eventLoop)
        }
        .flush(recorder)
        .always { _ in
            XCTAssertEqual(1, emitter.segments.count)
            let segment = try! XCTUnwrap(emitter.segments.first)
            XCTAssertEqual(1, segment._test_exceptions.count)
            if case Segment.State.emitted = segment._test_state {
            } else {
                XCTFail()
            }
        }
        .wait()
    }

    func testRecordingWithBaggageTaskError() {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        defer {
            XCTAssertNoThrow(try eventLoopGroup.syncShutdownGracefully())
        }

        enum TestError: Error {
            case test
        }

        func doWork(on eventLoop: EventLoop) -> EventLoopFuture<Void> {
            eventLoop.submit { throw TestError.test }.map { _ in }
        }

        let emitter = TestEmitter()
        let recorder = XRayRecorder(emitter: emitter)

        let eventLoop = eventLoopGroup.next()

        var baggage = BaggageContext()
        baggage.xRayContext = .init()
        try! recorder.segment(name: UUID().uuidString, baggage: baggage) {
            doWork(on: eventLoop)
        }
        .flush(recorder)
        .always { _ in
            XCTAssertEqual(1, emitter.segments.count)
            let segment = try! XCTUnwrap(emitter.segments.first)
            XCTAssertEqual(1, segment._test_exceptions.count)
            if case Segment.State.emitted = segment._test_state {
            } else {
                XCTFail()
            }
        }
        .wait()
    }

    func testEndingSegment() {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        defer {
            XCTAssertNoThrow(try eventLoopGroup.syncShutdownGracefully())
        }

        enum TestError: Error {
            case test
        }

        func doWork(on eventLoop: EventLoop) -> EventLoopFuture<Void> {
            eventLoop.submit { throw TestError.test }.map { _ in }
        }

        let emitter = TestEmitter()
        let recorder = XRayRecorder(emitter: emitter)

        let eventLoop = eventLoopGroup.next()

        let segment = recorder.beginSegment(name: UUID().uuidString, context: .init())
        try! doWork(on: eventLoop)
            .endSegment(segment)
            .flush(recorder)
            .always { _ in
                XCTAssertEqual(1, emitter.segments.count)
                let segment = try! XCTUnwrap(emitter.segments.first)
                XCTAssertEqual(1, segment._test_exceptions.count)
                if case Segment.State.emitted = segment._test_state {
                } else {
                    XCTFail()
                }
            }
            .wait()
    }
}
