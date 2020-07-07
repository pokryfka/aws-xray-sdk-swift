// TODO: remove dependency on Foundation
import struct Foundation.CharacterSet

// TODO: make more generic

extension XRayRecorder.TraceID {
    /// - returns: A 96-bit identifier for the trace, globally unique, in 24 hexadecimal digits.
    static func generateIdentifier() -> String {
        String(format: "%llx%llx", UInt64.random(in: UInt64.min ... UInt64.max) | 1 << 63,
               UInt32.random(in: UInt32.min ... UInt32.max) | 1 << 31)
    }
}

extension XRayRecorder.Segment {
    /// - returns: A 64-bit identifier for the segment, unique among segments in the same trace, in 16 hexadecimal digits.
    static func generateId() -> String {
        String(format: "%llx", UInt64.random(in: UInt64.min ... UInt64.max) | 1 << 63)
    }
}

extension XRayRecorder.Segment {
    static func validateId(_ string: String) throws -> String {
        let invalidCharacters = CharacterSet(charactersIn: "abcdef0123456789").inverted
        guard
            string.count == 16,
            string.rangeOfCharacter(from: invalidCharacters) == nil
        else {
            throw XRayRecorder.SegmentError.invalidID(string)
        }
        return string
    }

    // TODO: validate name
}
