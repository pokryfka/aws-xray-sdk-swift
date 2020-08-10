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

import AWSXRayUDPEmitter
import NIO

import struct Foundation.Data
import class Foundation.JSONEncoder

private extension JSONEncoder {
    func encode<T: Encodable>(_ value: T) throws -> String {
        String(decoding: try encode(value), as: UTF8.self)
    }
}

extension XRayUDPEmitter.SegmentEncoding {
    static let foundationJSON: XRayUDPEmitter.SegmentEncoding = {
        let jsonEncoder = JSONEncoder()
        return XRayUDPEmitter.SegmentEncoding { segment in
            ByteBuffer(string: try jsonEncoder.encode(segment))
        }
    }()
}
