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
        // TODO: random root traceId
        withTracingHeader("Root=1-5759e988-bd862e3fe1be46a994272793;Sampled=1")
    }

    static func withoutParentNotSampled() -> BaggageContext {
        // TODO: random root traceId
        withTracingHeader("Root=1-5759e988-bd862e3fe1be46a994272793;Sampled=0")
    }
}
