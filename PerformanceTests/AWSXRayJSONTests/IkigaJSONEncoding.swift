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
import IkigaJSON
import NIO

import struct Foundation.Data

extension XRayUDPEmitter.SegmentEncoding {
    static let ikigaJSON: XRayUDPEmitter.SegmentEncoding = {
        let jsonEncoder = IkigaJSONEncoder()
        return XRayUDPEmitter.SegmentEncoding { segment in
            // TODO: IkigaJSON README mentions writing directly to ByteBuffer
            // but it does not seem to be exposed?
            let data = try jsonEncoder.encode(segment)
            return ByteBuffer(string: String(decoding: data, as: UTF8.self))
        }
    }()
}
