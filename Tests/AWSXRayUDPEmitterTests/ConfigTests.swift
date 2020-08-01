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

@testable import AWSXRayUDPEmitter

private typealias Config = XRayUDPEmitter.Config

final class ConfigTests: XCTestCase {
    func testDefaultConfig() {
        let emitterConfig = Config()
        XCTAssertEqual("127.0.0.1:2000", emitterConfig.daemonEndpoint)
        XCTAssertEqual(Logger.Level.info, emitterConfig.logLevel)
    }

    func testEnvDaemonEndpoint() {
        // TODO: validate?
        for value in ["True", "TRUE", "FALSE"] {
            let config = Config { key in
                if key == "AWS_XRAY_DAEMON_ADDRESS" {
                    return value
                } else {
                    return nil
                }
            }
            XCTAssertEqual(value, config.daemonEndpoint)
        }
    }

    func testEnvLogLevelError() {
        let config = Config { key in
            if key == "XRAY_EMITTER_LOG_LEVEL" {
                return "error"
            } else {
                return nil
            }
        }
        XCTAssertEqual(Logger.Level.error, config.logLevel)
    }

    func testEnvLogLevelDefault() {
        let defaultConfig = Config()
        let invalidValues: [String?] = [nil, "DEBUG", "test"]
        for value in invalidValues {
            let config = Config { key in
                if key == "XRAY_EMITTER_LOG_LEVEL" {
                    return value
                } else {
                    return nil
                }
            }
            XCTAssertEqual(defaultConfig, config)
        }
    }
}
