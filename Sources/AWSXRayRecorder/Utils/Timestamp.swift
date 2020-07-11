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

extension Timestamp: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(secondsSinceEpoch)
    }
}
