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

// TODO: remove
extension XRayRecorder.Segment {
    /// A type representing the ability to encode a `XRayRecorder.Segment` to a String with its JSON representation.
    public struct Encoding {
        /// How to encode a segment  to JSON string.
        public let encode: (XRayRecorder.Segment) throws -> String

        public init(encode: @escaping (XRayRecorder.Segment) throws -> String) {
            self.encode = encode
        }
    }
}
