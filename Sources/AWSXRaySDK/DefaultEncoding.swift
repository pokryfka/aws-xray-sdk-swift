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
import PureSwiftJSON

internal extension XRayRecorder.Segment.Encoding {
    enum EncodingError: Error {
        case failedToCreateString
    }

    internal static let `default`: XRayRecorder.Segment.Encoding = {
        let jsonEncoder = PSJSONEncoder()
        return XRayRecorder.Segment.Encoding { segment in
            let bytes = try jsonEncoder.encode(segment)
            if let string = String(bytes: bytes, encoding: .utf8) {
                return string
            } else {
                throw EncodingError.failedToCreateString
            }
        }
    }()
}
