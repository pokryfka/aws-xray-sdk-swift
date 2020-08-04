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

import AnyCodable
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
