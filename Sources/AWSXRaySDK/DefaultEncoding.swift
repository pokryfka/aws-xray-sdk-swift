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
import PureSwiftJSON

extension XRayUDPEmitter.SegmentEncoding {
    /// Default encoding of `XRayRecorder.Segment` to JSON string.
    public static let `default`: XRayUDPEmitter.SegmentEncoding = {
        let jsonEncoder = PSJSONEncoder()
        return XRayUDPEmitter.SegmentEncoding { segment in
            ByteBuffer(bytes: try jsonEncoder.encode(segment))
        }
    }()
}
