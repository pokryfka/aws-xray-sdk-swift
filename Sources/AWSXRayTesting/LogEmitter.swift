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

/// "Emits" segments by logging them using provided logger instance.
public struct XRayLogEmitter: XRayEmitter {
    private let isShutdown = NIOAtomic<Bool>.makeAtomic(value: false)
    internal let logger: Logger
    private let encoding: XRayRecorder.Segment.Encoding

    /// Creates an instance of `XRayLogEmitter`.
    ///
    /// - Parameters:
    ///   - logger: logger instance.
    ///   - encoding: Contains encoder used to encode `XRayRecorder.Segment` to JSON string.
    public init(logger: Logger, encoding: XRayRecorder.Segment.Encoding? = nil) {
        self.logger = logger
        self.encoding = encoding ?? FoundationJSON.segmentEncoding
    }

    /// Creates an instance of `XRayLogEmitter`.
    ///
    /// - Parameters:
    ///   - label: logger label used to create a logger instance.
    ///   - onlyErrors: if `true`, only errors are logged.
    ///   - encoding: Contains encoder used to encode `XRayRecorder.Segment` to JSON string.
    public init(label: String? = nil, onlyErrors: Bool = false, encoding: XRayRecorder.Segment.Encoding? = nil) {
        let label = label ?? "xray.log_emitter.\(String.random32())"
        var logger = Logger(label: label)
        logger.logLevel = onlyErrors ? .error : .info
        self.logger = logger
        self.encoding = encoding ?? FoundationJSON.segmentEncoding
    }

    public func send(_ segment: XRayRecorder.Segment) {
        guard isShutdown.load() == false else {
            logger.warning("Emitter has been shut down")
            return
        }
        do {
            let document: String = try encoding.encode(segment)
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
