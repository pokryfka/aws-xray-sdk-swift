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

internal struct Timestamp: RawRepresentable {
    let rawValue: UInt64

    /// The number of seconds since the Unix epoch.
    var secondsSinceEpoch: Double { Double(Int64(bitPattern: rawValue)) / -1_000_000_000 }

    init?(rawValue: UInt64) {
        self.rawValue = rawValue
    }

    init() {
        rawValue = DispatchWallTime.now().rawValue
    }

    init?(secondsSinceEpoch: Double) {
        guard secondsSinceEpoch > 0 else { return nil }
        let nanosecondsSinceEpoch = UInt64(secondsSinceEpoch * 1_000_000_000)
        let seconds = UInt64(nanosecondsSinceEpoch / 1_000_000_000)
        let nanoseconds = nanosecondsSinceEpoch - (seconds * 1_000_000_000)
        rawValue = DispatchWallTime(timespec: timespec(tv_sec: Int(seconds), tv_nsec: Int(nanoseconds))).rawValue
    }
}

extension Timestamp: Equatable {
    static func == (lhs: Timestamp, rhs: Timestamp) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}

extension Timestamp: Comparable {
    static func < (lhs: Timestamp, rhs: Timestamp) -> Bool {
        // TODO: change implementation to compare integers
        lhs.secondsSinceEpoch < rhs.secondsSinceEpoch
    }
}

extension Timestamp: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(secondsSinceEpoch)
    }
}
