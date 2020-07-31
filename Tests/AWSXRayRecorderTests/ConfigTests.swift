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

    func testEnvDisabled() {
        let config = XRayRecorder.Config { key in
            if key == "AWS_XRAY_SDK_ENABLED" {
                return "false"
            } else {
                return nil
            }
        }
        XCTAssertFalse(config.enabled)
    }
    
    func testEnvEnabledTrue() {
        let config = XRayRecorder.Config { key in
            if key == "AWS_XRAY_SDK_ENABLED" {
                return "true"
            } else {
                return nil
            }
        }
        XCTAssertTrue(config.enabled)
    }

    func testEnvEnabledOverride() {
        let config = XRayRecorder.Config(enabled: true) { key in
            if key == "AWS_XRAY_SDK_ENABLED" {
                return "false"
            } else {
                return nil
            }
        }
        XCTAssertTrue(config.enabled)
    }

    func testEnvEnabledDefault() {
        let defaultConfig = XRayRecorder.Config()
        let invalidValues: [String?] = [nil, "True", "TRUE", "FALSE"]
        for value in invalidValues {
            let config = XRayRecorder.Config { key in
                if key == "AWS_XRAY_SDK_ENABLED" {
                    return value
                } else {
                    return nil
                }
            }
            XCTAssertEqual(defaultConfig, config)
        }
    }

    func testEnvDaemonEndpoint() {
        // TODO: validate?
        for value in ["True", "TRUE", "FALSE"] {
            let config = XRayRecorder.Config { key in
                if key == "AWS_XRAY_DAEMON_ADDRESS" {
                    return value
                } else {
                    return nil
                }
            }
            XCTAssertEqual(value, config.daemonEndpoint)
        }
    }

    func testEnvContextMissingStrategyLogError() {
        let config = XRayRecorder.Config { key in
            if key == "AWS_XRAY_CONTEXT_MISSING" {
                return "LOG_ERROR"
            } else {
                return nil
            }
        }
        XCTAssertEqual(XRayRecorder.Config.ContextMissingStrategy.logError, config.contextMissingStrategy)
    }

    func testEnvContextMissingStrategyRuntimeError() {
        let config = XRayRecorder.Config { key in
            if key == "AWS_XRAY_CONTEXT_MISSING" {
                return "RUNTIME_ERROR"
            } else {
                return nil
            }
        }
        XCTAssertEqual(XRayRecorder.Config.ContextMissingStrategy.runtimeError, config.contextMissingStrategy)
    }

    func testEnvContextMissingDefault() {
        let defaultConfig = XRayRecorder.Config()
        let invalidValues: [String?] = [nil, "LogError", "log_error", "RuntimeError", "runtime_error"]
        for value in invalidValues {
            let config = XRayRecorder.Config { key in
                if key == "LOG_ERROR" {
                    return value
                } else {
                    return nil
                }
            }
            XCTAssertEqual(defaultConfig, config)
        }
    }
}
