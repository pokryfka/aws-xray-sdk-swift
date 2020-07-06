import struct Dispatch.DispatchWallTime

internal struct Timestamp: RawRepresentable {
    let rawValue: UInt64

    /// The number of seconds since the Unix epoch.
    var secondsSinceEpoch: Double { Double(Int64(bitPattern: rawValue)) / -1_000_000_000 }

    @inlinable
    init?(rawValue: UInt64) {
        self.rawValue = rawValue
    }

    @inlinable
    init() {
        rawValue = DispatchWallTime.now().rawValue
    }
}
