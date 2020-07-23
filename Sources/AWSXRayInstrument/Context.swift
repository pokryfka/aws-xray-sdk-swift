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

internal extension XRayRecorder.TraceContext {
    init(tracingHeader: String) throws {
        try self.init(string: tracingHeader)
    }

    var tracingHeader: String {
        let segments: [String?] = [
            "Root=\(traceId)",
            {
                guard let parentId = parentId else { return nil }
                return "Parent=\(parentId.rawValue)"
            }(),
            {
                guard sampled != .unknown else { return nil }
                return sampled.rawValue
            }(),
        ]
        return segments.compactMap { $0 }.joined(separator: ";")
    }
}

extension XRayRecorder.TraceContext: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.traceId == rhs.traceId
            && lhs.parentId == rhs.parentId
            && lhs.sampled == rhs.sampled
    }
}

public extension XRayRecorder {
    func beginSegment(name: String, context: BaggageContext,
                      aws: Segment.AWS? = nil, metadata: Segment.Metadata? = nil) -> XRayRecorder.Segment {
        // TODO: use `AWS_XRAY_CONTEXT_MISSING` to configure how to handle missing context
        // parse it in `XRayRecorder.Config`
        guard let context = context.xRayContext else {
            // TODO: obviously it should not fail by default
            // currently there is no public init to create new Trace,
            // will not be a problem when moved to `XRayRecorder`
            preconditionFailure("Missing context")
        }

        return beginSegment(name: name, context: context, aws: aws, metadata: metadata)
    }
}
