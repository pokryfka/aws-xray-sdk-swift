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
    func testRecordingExceptionsWithMessageAndType() {
        let segment = Segment(id: .init(), name: UUID().uuidString, context: .init(), baggage: .init())

        let messageWithType = (UUID().uuidString, UUID().uuidString)
        segment.addException(message: messageWithType.0, type: messageWithType.1)

        let messageWithoutType = UUID().uuidString
        segment.addException(message: messageWithoutType)

        let exceptions = segment.exceptions
        XCTAssertEqual(2, exceptions.count)
        XCTAssertEqual(messageWithType.0, exceptions[0].message)
        XCTAssertEqual(messageWithType.1, exceptions[0].type)
        XCTAssertEqual(messageWithoutType, exceptions[1].message)
        XCTAssertNil(exceptions[1].type)
    }

    func testRecordingErrors() {
        let segment = Segment(id: .init(), name: UUID().uuidString, context: .init(), baggage: .init())

        enum TestError: Error {
            case test1
            case test2
        }

        segment.addError(TestError.test1)
        segment.addError(TestError.test2)

        let exceptions = segment.exceptions
        XCTAssertEqual(2, exceptions.count)
        XCTAssertEqual("test1", exceptions[0].message) // may be a bit different
        XCTAssertNil(exceptions[0].type)
        XCTAssertEqual("test2", exceptions[1].message) // may be a bit different
        XCTAssertNil(exceptions[1].type)
    }

    func testRecordingHttpErrors() {
        let segment = Segment(id: .init(), name: UUID().uuidString, context: .init(), baggage: .init())

        let errorWithoutCause = Segment.HTTPError.throttle(cause: nil)
        let errorWithCause = Segment.HTTPError.server(statusCode: 500, cause: .init(message: "Error 500", type: nil))

        segment.addError(errorWithoutCause)
        segment.addError(errorWithCause)

        let exceptions = segment.exceptions
        XCTAssertEqual(1, exceptions.count)
        XCTAssertEqual("Error 500", exceptions.first?.message)
        XCTAssertNil(exceptions.first?.type)
    }
}
