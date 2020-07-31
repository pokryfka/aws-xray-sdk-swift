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

import struct Foundation.Data
import class Foundation.JSONEncoder

private extension JSONEncoder {
    func encode<T: Encodable>(_ value: T) throws -> String {
        String(decoding: try encode(value), as: UTF8.self)
    }
}

private extension String {
    /// - returns: A 32-bit identifier in 8 hexadecimal digits.
    static func random32() -> String {
        String(UInt32.random(in: UInt32.min ... UInt32.max) | 1 << 31, radix: 16, uppercase: false)
    }
}

public struct XRayLogEmitter: XRayEmitter {
    private let logger: Logger

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }()

    public init(logger: Logger) {
        self.logger = logger
    }

    public init(label: String? = nil) {
        let label = label ?? "xray.log_emitter.\(String.random32())"
        logger = Logger(label: label)
    }

    public func send(_ segment: XRayRecorder.Segment) {
        do {
            let document: String = try encoder.encode(segment)
            logger.info("\n\(document)")
        } catch {
            logger.error("Failed to encode a segment: \(error)")
        }
    }

    public func flush(_: @escaping (Error?) -> Void) {}
}
