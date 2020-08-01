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

extension XRayUDPEmitter {
    public struct Config {
        internal let daemonEndpoint: String
        internal let logLevel: Logger.Level

        internal init(daemonEndpoint: String? = nil, logLevel: Logger.Level? = nil, env: (String) -> String?) {
            self.daemonEndpoint = daemonEndpoint ?? env("AWS_XRAY_DAEMON_ADDRESS") ?? "127.0.0.1:2000"
            self.logLevel = logLevel ?? env("XRAY_RECORDER_LOG_LEVEL").flatMap(Logger.Level.init) ?? .info
        }

        /// - Parameters:
        ///   - daemonEndpoint: the IP address and port of the X-Ray daemon listener, `127.0.0.1:2000` by default;
        ///   if not specified the value of the `AWS_XRAY_DAEMON_ADDRESS` environment variable is used.
        ///   - logLevel: [swift-log](https://github.com/apple/swift-log) logging level, `info` by default;
        ///   if not specified the value of the `XRAY_RECORDER_LOG_LEVEL` environment variable is used.
        public init(daemonEndpoint: String? = nil, logLevel: Logger.Level? = nil) {
            self.init(daemonEndpoint: daemonEndpoint, logLevel: logLevel, env: _env)
        }
    }
}

extension XRayUDPEmitter.Config: Equatable {}

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
