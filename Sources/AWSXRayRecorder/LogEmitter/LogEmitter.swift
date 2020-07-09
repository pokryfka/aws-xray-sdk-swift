import Logging

import struct Foundation.Data
import class Foundation.JSONEncoder

private extension JSONEncoder {
    func encode<T: Encodable>(_ value: T) throws -> String {
        String(decoding: try encode(value), as: UTF8.self)
    }
}

// TODO: document

public struct XRayLogEmitter: XRayEmitter {
    private let logger: Logger

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }()

    public init(label: String? = nil) {
        let label = label ?? "xray.log_emitter.\(String.random32())"
        logger = Logger(label: label)
    }

    public func send(_ segment: XRayRecorder.Segment) {
        do {
            let document: String = try encoder.encode(segment)
            logger.info("\n\(document)")
        } catch {
            logger.error("Failed to encode a segment: \(error)")
        }
    }

    public func flush(_: @escaping (Error?) -> Void) {}
}
