internal extension String {
    /// - returns: A 32-bit identifier in 8 hexadecimal digits.
    static func random32() -> String {
        String(UInt32.random(in: UInt32.min ... UInt32.max) | 1 << 31, radix: 16, uppercase: false)
    }

    /// - returns: A 64-bit identifier in 16 hexadecimal digits.
    static func random64() -> String {
        String(UInt64.random(in: UInt64.min ... UInt64.max) | 1 << 63, radix: 16, uppercase: false)
    }

    /// - returns: A 96-bit identifier in 24 hexadecimal digits.
    static func random96() -> String {
        random64() + random32()
    }
}
