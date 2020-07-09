import struct Foundation.Data
import class Foundation.JSONEncoder

private extension JSONEncoder {
    func encode<T: Encodable>(_ value: T) throws -> String {
        String(decoding: try encode(value), as: UTF8.self)
    }
}

private let jsonEncoder = JSONEncoder()

extension XRayRecorder.Segment {
    public func JSONString() throws -> String {
        try jsonEncoder.encode(self) as String
    }
}
