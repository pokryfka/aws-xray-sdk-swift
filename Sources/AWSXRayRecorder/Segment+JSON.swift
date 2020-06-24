import struct Foundation.Data
import class Foundation.JSONEncoder

extension JSONEncoder {
    fileprivate func encode<T: Encodable>(_ value: T) throws -> String {
        String(decoding: try encode(value), as: UTF8.self)
    }
}

private let jsonEncoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    encoder.dateEncodingStrategy = .iso8601
    encoder.keyEncodingStrategy = .convertToSnakeCase
    return encoder
}()

extension XRayRecorder.Segment {
    func JSONString() throws -> String {
        try lock.withLock { try jsonEncoder.encode(self) as String }
    }
}
