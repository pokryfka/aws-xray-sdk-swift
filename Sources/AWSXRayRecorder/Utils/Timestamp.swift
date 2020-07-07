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
