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

private extension String {
    /// - returns: A 32-bit identifier in 8 hexadecimal digits.
    static func random32() -> String {
        String(UInt32.random(in: UInt32.min ... UInt32.max) | 1 << 31, radix: 16, uppercase: false)
    }
}

public struct XRayLogEmitter: XRayEmitter {
    private let logger: Logger
    private let encoder: XRayRecorder.SegmentEncoder

    public init(logger: Logger, encoder: @escaping XRayRecorder.SegmentEncoder) {
        self.logger = logger
        self.encoder = encoder
    }

    public init(label: String? = nil, encoder: XRayRecorder.SegmentEncoder? = nil) {
        let label = label ?? "xray.log_emitter.\(String.random32())"
        logger = Logger(label: label)
        self.encoder = encoder ?? FoundationJSON.segmentEncoder
    }

    public func send(_ segment: XRayRecorder.Segment) {
        do {
            let document: String = try encoder(segment)
            logger.info("\n\(document)")
        } catch {
            logger.error("Failed to encode a segment: \(error)")
        }
    }

    public func flush(_: @escaping (Error?) -> Void) {}
}
