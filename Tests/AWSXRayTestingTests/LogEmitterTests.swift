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

import AWSXRayRecorder
@testable import AWSXRayTesting

final class LogEmitterTests: XCTestCase {
    func testDetaultLogLevel() {
        let emitter = XRayLogEmitter()
        XCTAssertEqual(Logger.Level.info, emitter.logger.logLevel)
    }

    func testErrorsOnlyLogLevel() {
        let emitter = XRayLogEmitter(onlyErrors: true)
        XCTAssertEqual(Logger.Level.error, emitter.logger.logLevel)
    }

    func testEmmiting() {
        let logHandler = TestLogHandler()
        let logger = Logger(label: "test", factory: { _ in logHandler })
        let emitter = XRayLogEmitter(logger: logger)
        let recorder = XRayRecorder(emitter: emitter)
        let context = XRayRecorder.TraceContext()

        XCTAssertEqual(0, logHandler.errorMessages.count)
        XCTAssertEqual(0, logHandler.warningMessages.count)
        XCTAssertEqual(0, logHandler.infoMessages.count)

        recorder.segment(name: UUID().uuidString, context: context) { _ in }
        recorder.wait()

        XCTAssertEqual(0, logHandler.errorMessages.count)
        XCTAssertEqual(0, logHandler.warningMessages.count)
        XCTAssertEqual(1, logHandler.infoMessages.count)
    }

    func testFlushing() {
        let logHandler = TestLogHandler()
        let logger = Logger(label: "test", factory: { _ in logHandler })
        let emitter = XRayLogEmitter(logger: logger)

        // make sure the callback is ... called
        let exp = expectation(description: "hasFlushed")
        emitter.flush { error in
            XCTAssertNil(error)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }

    func testShutdown() {
        let logHandler = TestLogHandler()
        let logger = Logger(label: "test", factory: { _ in logHandler })
        let emitter = XRayLogEmitter(logger: logger)
        let recorder = XRayRecorder(emitter: emitter)
        let context = XRayRecorder.TraceContext()

        XCTAssertEqual(0, logHandler.errorMessages.count)
        XCTAssertEqual(0, logHandler.warningMessages.count)
        XCTAssertEqual(0, logHandler.infoMessages.count)

        recorder.segment(name: UUID().uuidString, context: context) { _ in }
        recorder.wait()

        // make sure the callback is ... called
        let exp = expectation(description: "hasShutdown")
        emitter.shutdown { error in
            XCTAssertNil(error)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)

        XCTAssertEqual(0, logHandler.errorMessages.count)
        XCTAssertEqual(0, logHandler.warningMessages.count)
        XCTAssertEqual(1, logHandler.infoMessages.count)

        // cannot send after shutdown, logged as warning
        recorder.segment(name: UUID().uuidString, context: context) { _ in }
        recorder.wait()

        XCTAssertEqual(0, logHandler.errorMessages.count)
        XCTAssertEqual(1, logHandler.warningMessages.count)
        XCTAssertEqual(1, logHandler.infoMessages.count)
    }
}
