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

extension XRayRecorder {
    /// `XRayRecorder` configuration.
    public struct Config {
        /// Context missing strategy.
        public enum ContextMissingStrategy: String {
            /// Indicate that a precondition was violated.
            case runtimeError = "RUNTIME_ERROR"
            /// Log an error and continue.
            case logError = "LOG_ERROR"
        }

        internal let enabled: Bool
        internal let contextMissingStrategy: ContextMissingStrategy
        internal let logLevel: Logger.Level
        internal let serviceVersion: String

        internal init(
            enabled: Bool? = nil,
            contextMissingStrategy: ContextMissingStrategy? = nil,
            logLevel: Logger.Level? = nil,
            serviceVersion: String? = nil,
            env: (String) -> String?
        ) {
            self.enabled = enabled ?? (env("AWS_XRAY_SDK_ENABLED").flatMap(Bool.init) ?? true)
            self.contextMissingStrategy = contextMissingStrategy ??
                env("AWS_XRAY_CONTEXT_MISSING").flatMap(ContextMissingStrategy.init) ?? .logError
            self.logLevel = logLevel ?? env("XRAY_RECORDER_LOG_LEVEL").flatMap(Logger.Level.init) ?? .info
            self.serviceVersion = serviceVersion ?? "aws-xray-sdk-swift"
        }

        /// Creates new `XRayRecorder` configuration.
        ///
        /// - Parameters:
        ///   - enabled: set `false` to disable tracing, enabled by default unless `AWS_XRAY_SDK_ENABLED` environment variable is set to false.
        ///   - daemonEndpoint: the IP address and port of the X-Ray daemon listener, `127.0.0.1:2000` by default;
        ///   if not specified the value of the `AWS_XRAY_DAEMON_ADDRESS` environment variable is used.
        ///   - contextMissingStrategy: configures how missing context is handled, `.logError` by default;
        ///   if not specified the value of the `AWS_XRAY_CONTEXT_MISSING` environment variable is used:
        ///     - `RUNTIME_ERROR` - Indicate that a precondition was violated.
        ///     - `LOG_ERROR` - Log an error and continue.
        ///   - logLevel: [swift-log](https://github.com/apple/swift-log) logging level, `info` by default;
        ///   if not specified the value of the `XRAY_RECORDER_LOG_LEVEL` environment variable is used.
        ///   - serviceVersion: A string that identifies the version of your application that served the request, `aws-xray-sdk-swift` by default.
        public init(
            enabled: Bool? = nil,
            contextMissingStrategy: ContextMissingStrategy? = nil,
            logLevel: Logger.Level? = nil,
            serviceVersion: String? = nil
        ) {
            self.init(enabled: enabled,
                      contextMissingStrategy: contextMissingStrategy,
                      logLevel: logLevel,
                      serviceVersion: serviceVersion,
                      env: _env)
        }
    }
}

extension XRayRecorder.Config: Equatable {}

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

private func _env(_ name: String) -> String? {
    #if canImport(Darwin)
    guard let value = getenv(name) else { return nil }
    return String(cString: value)
    #elseif canImport(Glibc)
    guard let value = getenv(name) else { return nil }
    return String(cString: value)
    #else
    return nil
    #endif
}
