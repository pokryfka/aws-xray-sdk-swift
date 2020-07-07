internal extension String {
    /// - returns: A 64-bit identifier in 24 hexadecimal digits.
    @inlinable
    static func random64() -> String {
        String(UInt64.random(in: UInt64.min ... UInt64.max) | 1 << 63, radix: 16, uppercase: false)
    }

    /// - returns: A 96-bit identifier in 24 hexadecimal digits.
    @inlinable
    static func random96() -> String {
        String(UInt64.random(in: UInt64.min ... UInt64.max) | 1 << 63, radix: 16, uppercase: false)
            + String(UInt32.random(in: UInt32.min ... UInt32.max) | 1 << 31, radix: 16, uppercase: false)
    }
}
