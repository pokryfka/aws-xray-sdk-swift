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

import struct Dispatch.DispatchWallTime

#if canImport(Darwin)
import Darwin // timespec
#else
import Glibc // timespec
#endif

extension XRayRecorder {
    public struct Timestamp {
        /// It's already the past.
        public static func now() -> Timestamp {
            Timestamp()
        }

        private let rawValue: DispatchWallTime

        /// The number of seconds since the Unix epoch.
        internal var secondsSinceEpoch: Double { Double(Int64(bitPattern: rawValue.rawValue)) / -1_000_000_000 }

        internal init?(rawValue: DispatchWallTime) {
            self.rawValue = rawValue
        }

        internal init() {
            rawValue = DispatchWallTime.now()
        }

        internal init?(secondsSinceEpoch: Double) {
            guard secondsSinceEpoch > 0 else { return nil }
            let nanosecondsSinceEpoch = UInt64(secondsSinceEpoch * 1_000_000_000)
            let seconds = UInt64(nanosecondsSinceEpoch / 1_000_000_000)
            let nanoseconds = nanosecondsSinceEpoch - (seconds * 1_000_000_000)
            rawValue = DispatchWallTime(timespec: timespec(tv_sec: Int(seconds), tv_nsec: Int(nanoseconds)))
        }
    }
}

extension XRayRecorder.Timestamp: Equatable {
    public static func == (lhs: XRayRecorder.Timestamp, rhs: XRayRecorder.Timestamp) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}

extension XRayRecorder.Timestamp: Comparable {
    public static func < (lhs: XRayRecorder.Timestamp, rhs: XRayRecorder.Timestamp) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension XRayRecorder.Timestamp: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(secondsSinceEpoch)
    }
}
