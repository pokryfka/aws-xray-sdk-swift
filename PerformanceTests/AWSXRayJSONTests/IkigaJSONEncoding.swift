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
import IkigaJSON

internal enum Ikiga {
    static let segmentEncoding: XRayRecorder.Segment.Encoding = {
        let jsonEncoder = IkigaJSONEncoder()
        return XRayRecorder.Segment.Encoding { segment in
            let data = try jsonEncoder.encode(segment) // uses Foundation.Data
            return String(decoding: data, as: UTF8.self)
        }
    }()
}
