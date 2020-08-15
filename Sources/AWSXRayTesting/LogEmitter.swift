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

import AWSXRayRecorder
import Logging
import NIOConcurrencyHelpers

import struct Foundation.Data
import class Foundation.JSONEncoder

private extension JSONEncoder {
    func encode<T: Encodable>(_ value: T) throws -> String {
        String(decoding: try encode(value), as: UTF8.self)
    }
}

/// "Emits" segments by logging them using provided logger instance.
public struct XRayLogEmitter: XRayEmitter {
    private let isShutdown = NIOAtomic<Bool>.makeAtomic(value: false)
    internal let logger: Logger

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }()

    /// Creates an instance of `XRayLogEmitter`.
    ///
    /// - Parameters:
    ///   - logger: logger instance.
    public init(logger: Logger) {
        self.logger = logger
    }

    /// Creates an instance of `XRayLogEmitter`.
    ///
    /// - Parameters:
    ///   - label: logger label used to create a logger instance.
    ///   - onlyErrors: if `true`, only errors are logged.
    public init(label: String? = nil, onlyErrors: Bool = false) {
        let label = label ?? "xray.log_emitter"
        var logger = Logger(label: label)
        logger.logLevel = onlyErrors ? .error : .info
        self.logger = logger
    }

    public func send(_ segment: XRayRecorder.Segment) {
        guard isShutdown.load() == false else {
            logger.warning("Emitter has been shut down")
            return
        }
        do {
            let document: String = try encoder.encode(segment)
            logger.info("\n\(document)")
        } catch {
            logger.error("Failed to encode a segment: \(error)")
        }
    }

    public func flush(_ callback: @escaping (Error?) -> Void) { callback(nil) }

    public func shutdown(_ callback: @escaping (Error?) -> Void) {
        isShutdown.store(true)
        callback(nil)
    }
}
