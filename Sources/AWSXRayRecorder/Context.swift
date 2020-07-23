import Baggage

private enum AmazonHeaders {
    static let traceing = "X-Amzn-Trace-Id"
}

private enum XRayTraceIDKey: BaggageContextKey {
    typealias Value = XRayRecorder.TraceContext

    var name: String {
        "XRayContext"
    }
}

extension BaggageContext {
    var xRayTraceID: XRayRecorder.TraceContext? {
        get {
            self[XRayTraceIDKey.self]
        }
        set {
            self[XRayTraceIDKey.self] = newValue
        }
    }
}

// self.instrument.extract(requestHead.headers, into: &baggage, using: HTTPHeadersExtractor())

//// extract
// if let traceID = extractor.extract(key: "X-Amzn-Trace-Id", from: carrier) {
//    baggage.xRayTraceID = traceID
// }
//
//// inject
// if let traceID = baggage.xRayTraceID {
//    injector.inject(traceID, forKey: "X-Amzn-Trace-Id", into: &carrier)
// }
