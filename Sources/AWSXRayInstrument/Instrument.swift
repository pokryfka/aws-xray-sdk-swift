import AWSXRayRecorder
import Baggage
import Dispatch // DispatchTime
import Instrumentation

extension XRayRecorder: TracingInstrument {
    public func extract<Carrier, Extractor>(_ carrier: Carrier, into baggage: inout BaggageContext, using extractor: Extractor) where Carrier == Extractor.Carrier, Extractor: ExtractorProtocol {
        guard let tracingHeader = extractor.extract(key: AmazonHeaders.traceId, from: carrier) else { return }

        if let context = try? XRayContext(tracingHeader: tracingHeader) {
            baggage.xRayContext = context
        }
    }

    public func inject<Carrier, Injector>(_ baggage: BaggageContext, into carrier: inout Carrier, using injector: Injector) where Carrier == Injector.Carrier, Injector: InjectorProtocol {
        guard let context = baggage.xRayContext else { return }

        injector.inject(context.tracingHeader, forKey: AmazonHeaders.traceId, into: &carrier)
    }

    public func startSpan(named operationName: String, context: BaggageContext, ofKind kind: SpanKind, at timestamp: DispatchTime?) -> Span {
        // TODO: map time type, see https://github.com/slashmo/gsoc-swift-tracing/pull/82#issuecomment-661868753
        // TODO: does kind map anyhow to Subsegment?
        beginSegment(name: operationName, context: context)
    }
}
