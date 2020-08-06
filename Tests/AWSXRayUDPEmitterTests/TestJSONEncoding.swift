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

import struct Foundation.Data
import class Foundation.JSONEncoder

internal enum TestJSON {
    static let segmentEncoding: XRayRecorder.Segment.Encoding = {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        return XRayRecorder.Segment.Encoding { segment in
            String(decoding: try jsonEncoder.encode(segment), as: UTF8.self)
        }
    }()
}
