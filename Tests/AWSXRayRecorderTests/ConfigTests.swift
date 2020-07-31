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

final class ConfigTests: XCTestCase {
    func testDefaultConfig() {
        let config = XRayRecorder.Config()
        XCTAssertTrue(config.enabled)
        XCTAssertEqual("127.0.0.1:2000", config.daemonEndpoint)
        XCTAssertEqual(XRayRecorder.Config.ContextMissingStrategy.logError, config.contextMissingStrategy)
        XCTAssertEqual(Logger.Level.info, config.logLevel)
        XCTAssertEqual("aws-xray-sdk-swift", config.serviceVersion)

        let emitterConfig = XRayUDPEmitter.Config()
        XCTAssertEqual("127.0.0.1:2000", emitterConfig.daemonEndpoint)
        XCTAssertEqual(Logger.Level.info, emitterConfig.logLevel)

        XCTAssertEqual(config.daemonEndpoint, emitterConfig.daemonEndpoint)
        XCTAssertEqual(config.logLevel, emitterConfig.logLevel)
    }

    func testCopyConfig() {
        let config = XRayRecorder.Config(daemonEndpoint: "127.0.0.1:4000", logLevel: .debug)
        let emitterConfig = XRayUDPEmitter.Config(config)
        XCTAssertEqual(config.daemonEndpoint, emitterConfig.daemonEndpoint)
        XCTAssertEqual(config.logLevel, emitterConfig.logLevel)
    }
}
