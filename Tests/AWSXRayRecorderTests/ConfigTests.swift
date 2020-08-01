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

private typealias Config = XRayRecorder.Config

final class ConfigTests: XCTestCase {
    func testDefaultConfig() {
        let config = Config()
        XCTAssertTrue(config.enabled)
        XCTAssertEqual(XRayRecorder.Config.ContextMissingStrategy.logError, config.contextMissingStrategy)
        XCTAssertEqual(Logger.Level.info, config.logLevel)
        XCTAssertEqual("aws-xray-sdk-swift", config.serviceVersion)
    }

    func testEnvDisabled() {
        let config = Config { key in
            if key == "AWS_XRAY_SDK_ENABLED" {
                return "false"
            } else {
                return nil
            }
        }
        XCTAssertFalse(config.enabled)
    }

    func testEnvEnabledTrue() {
        let config = Config { key in
            if key == "AWS_XRAY_SDK_ENABLED" {
                return "true"
            } else {
                return nil
            }
        }
        XCTAssertTrue(config.enabled)
    }

    func testEnvEnabledOverride() {
        let config = Config(enabled: true) { key in
            if key == "AWS_XRAY_SDK_ENABLED" {
                return "false"
            } else {
                return nil
            }
        }
        XCTAssertTrue(config.enabled)
    }

    func testEnvEnabledDefault() {
        let defaultConfig = Config()
        let invalidValues: [String?] = [nil, "True", "TRUE", "FALSE"]
        for value in invalidValues {
            let config = Config { key in
                if key == "AWS_XRAY_SDK_ENABLED" {
                    return value
                } else {
                    return nil
                }
            }
            XCTAssertEqual(defaultConfig, config)
        }
    }

    func testEnvContextMissingStrategyLogError() {
        let config = Config { key in
            if key == "AWS_XRAY_CONTEXT_MISSING" {
                return "LOG_ERROR"
            } else {
                return nil
            }
        }
        XCTAssertEqual(XRayRecorder.Config.ContextMissingStrategy.logError, config.contextMissingStrategy)
    }

    func testEnvContextMissingStrategyRuntimeError() {
        let config = Config { key in
            if key == "AWS_XRAY_CONTEXT_MISSING" {
                return "RUNTIME_ERROR"
            } else {
                return nil
            }
        }
        XCTAssertEqual(XRayRecorder.Config.ContextMissingStrategy.runtimeError, config.contextMissingStrategy)
    }

    func testEnvContextMissingDefault() {
        let defaultConfig = Config()
        let invalidValues: [String?] = [nil, "LogError", "log_error", "RuntimeError", "runtime_error"]
        for value in invalidValues {
            let config = Config { key in
                if key == "LOG_ERROR" {
                    return value
                } else {
                    return nil
                }
            }
            XCTAssertEqual(defaultConfig, config)
        }
    }

    func testEnvLogLevelError() {
        let config = Config { key in
            if key == "XRAY_RECORDER_LOG_LEVEL" {
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
                if key == "XRAY_RECORDER_LOG_LEVEL" {
                    return value
                } else {
                    return nil
                }
            }
            XCTAssertEqual(defaultConfig, config)
        }
    }
}
