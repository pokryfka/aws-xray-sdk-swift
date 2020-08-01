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

/// "Emits" segments by logging them using provided logger instance.
public struct XRayLogEmitter: XRayEmitter {
    private let logger: Logger
    private let encoding: XRayRecorder.Segment.Encoding

    public init(logger: Logger, encoding: XRayRecorder.Segment.Encoding? = nil) {
        self.logger = logger
        self.encoding = encoding ?? FoundationJSON.segmentEncoding
    }

    public init(label: String? = nil, encoding: XRayRecorder.Segment.Encoding? = nil) {
        let label = label ?? "xray.log_emitter.\(String.random32())"
        logger = Logger(label: label)
        self.encoding = encoding ?? FoundationJSON.segmentEncoding
    }

    public func send(_ segment: XRayRecorder.Segment) {
        do {
            let document: String = try encoding.encode(segment)
            logger.info("\n\(document)")
        } catch {
            logger.error("Failed to encode a segment: \(error)")
        }
    }

    public func flush(_: @escaping (Error?) -> Void) {}
}
