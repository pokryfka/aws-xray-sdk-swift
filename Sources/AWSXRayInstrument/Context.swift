// TODO: move to XRayRecorder at some point

import AWSXRayRecorder
import Baggage

// TODO: consider renaming the type
internal typealias XRayContext = XRayRecorder.TraceContext

internal enum AmazonHeaders {
    static let traceId = "X-Amzn-Trace-Id"
}

private enum XRayContextKey: BaggageContextKey {
    typealias Value = XRayContext

    var name: String { "XRayContext" }
}

internal extension BaggageContext {
    var xRayContext: XRayContext? {
        get {
            self[XRayContextKey.self]
        }
        set {
            self[XRayContextKey.self] = newValue
        }
    }
}

public extension XRayRecorder {
    func beginSegment(name: String, context: BaggageContext,
                      aws: Segment.AWS? = nil, metadata: Segment.Metadata? = nil) -> XRayRecorder.Segment {
        // TODO: use `AWS_XRAY_CONTEXT_MISSING` to configure how to handle missing context
        // TODO: log error if context is missing, create new trace
        let context = context.xRayContext ?? TraceContext(sampled: .unknown)
        return beginSegment(name: name, context: context, aws: aws, metadata: metadata)
    }
}
