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
import Logging
import XCTest

@testable import AWSXRayRecorder

private typealias TraceContext = XRayRecorder.TraceContext

final class ContextTests: XCTestCase {
    func testMissingContext() {
        let logHandler = TestLogHandler()
        let logger = Logger(label: "test", factory: { _ in logHandler })

        let recorder = XRayRecorder(emitter: XRayNoOpEmitter(), logger: logger)
        let baggage = BaggageContext()
        _ = recorder.beginSegment(name: UUID().uuidString, baggage: baggage)
        XCTAssertEqual(1, logHandler.errorMessages.count)
    }
}
