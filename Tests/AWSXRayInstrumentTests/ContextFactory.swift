import Baggage

@testable import AWSXRayInstrument

extension BaggageContext {
    static func empty() -> BaggageContext {
        BaggageContext()
    }

    static func withTracingHeader(_ tracingHeader: String) -> BaggageContext {
        var context = BaggageContext()
        context.xRayContext = try? XRayContext(tracingHeader: tracingHeader)
        return context
    }

    static func withoutParentSampled() -> BaggageContext {
        var context = BaggageContext()
        context.xRayContext = XRayContext(traceId: .init(), parentId: nil, sampled: .sampled)
        return context
    }

    static func withoutParentNotSampled() -> BaggageContext {
        var context = BaggageContext()
        context.xRayContext = XRayContext(traceId: .init(), parentId: nil, sampled: .notSampled)
        return context
    }
}
