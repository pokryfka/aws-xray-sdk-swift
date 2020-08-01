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
import AWSXRayTesting

final class LogEmitterTests: XCTestCase {
    func testEmmiting() {
        let logHandler = TestLogHandler()
        let logger = Logger(label: "test", factory: { _ in logHandler })
        let emitter = XRayLogEmitter(logger: logger)
        let recorder = XRayRecorder(emitter: emitter)
        let context = XRayRecorder.TraceContext()

        let segment = recorder.beginSegment(name: UUID().uuidString, context: context)
        segment.end()

        recorder.wait()

        XCTAssertEqual(0, logHandler.errorMessages.count)
        XCTAssertEqual(1, logHandler.infoMessages.count)
    }
}
