import Baggage

// TODO: this code is not used anywhere, yet... ;-)

internal enum AmazonHeaders {
    static let traceID = "X-Amzn-Trace-Id"
}

// TODO: not sure if the Valeu should be a String or perhaps RawRepresentabel struct (?)

private enum AmazonTraceIDKey: BaggageContextKey {
    typealias Value = String
}

extension BaggageContext {
    var xRayTraceID: String? {
        get {
            self[AmazonTraceIDKey.self]
        }
        set {
            self[AmazonTraceIDKey.self] = newValue
        }
    }
}

//// extract
// if let traceID = extractor.extract(key: "X-Amzn-Trace-Id", from: carrier) {
//    baggage.xRayTraceID = traceID
// }
//
//// inject
// if let traceID = baggage.xRayTraceID {
//    injector.inject(traceID, forKey: "X-Amzn-Trace-Id", into: &carrier)
// }
