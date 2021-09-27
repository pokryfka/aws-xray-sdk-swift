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

final class SegmentLoggingTests: XCTestCase {
    private typealias Timestamp = XRayRecorder.Timestamp
    private typealias Segment = XRayRecorder.Segment
    private typealias SegmentError = XRayRecorder.SegmentError

    func testLoggingStateChangeErrors() {
        let logHandler = TestLogHandler()
        let logger = Logger(label: "test", factory: { _ in logHandler })

        let now = Date().timeIntervalSince1970
        let startTime = Timestamp(secondsSinceEpoch: now)!
        let beforeTime = Timestamp(secondsSinceEpoch: now - 1)!

        var numErrors: Int = 0

        let segment = Segment(id: .init(), name: UUID().uuidString, context: .init(), baggage: .topLevel,
                              startTime: startTime,
                              logger: logger)

        // cannot emit if still in progress
        XCTAssertThrowsError(try segment.emit()) { error in
            guard case SegmentError.inProgress = error else {
                XCTFail()
                return
            }
            numErrors += 1
        }

        // cannot end before started
        XCTAssertThrowsError(try segment.end(beforeTime)) { error in
            guard case SegmentError.backToTheFuture = error else {
                XCTFail()
                return
            }
            numErrors += 1
        }

        XCTAssertNoThrow(try segment.end(Timestamp()))

        // cannot end if already end
        XCTAssertThrowsError(try segment.end(Timestamp())) { error in
            guard case SegmentError.alreadyEnded = error else {
                XCTFail()
                return
            }
            numErrors += 1
        }
        // public API does not throw but should log the error
        segment.end()
        numErrors += 1

        XCTAssertNoThrow(try segment.emit())

        // cannot emit twice
        XCTAssertThrowsError(try segment.emit()) { error in
            guard case SegmentError.alreadyEmitted = error else {
                XCTFail()
                return
            }
            numErrors += 1
        }

        // nor end after emitted
        XCTAssertThrowsError(try segment.end(Timestamp())) { error in
            guard case SegmentError.alreadyEmitted = error else {
                XCTFail()
                return
            }
            numErrors += 1
        }

        XCTAssertEqual(numErrors, logHandler.errorMessages.count)
    }

    func testLoggingNotEmmitedSegment() {
        let logHandler = TestLogHandler()
        let logger = Logger(label: "test", factory: { _ in logHandler })

        var segment: Segment? = Segment(id: .init(), name: UUID().uuidString, context: .init(), baggage: .topLevel,
                                        logger: logger)
        XCTAssertTrue(segment!.isSampled)
        segment = nil
        XCTAssertEqual(1, logHandler.errorMessages.count)
    }
}
