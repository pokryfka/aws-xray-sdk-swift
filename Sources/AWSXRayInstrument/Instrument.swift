import AWSXRayRecorder
import Baggage
import Dispatch
import Instrumentation

extension XRayRecorder: TracingInstrument {
    public func extract<Carrier, Extractor>(_ carrier: Carrier, into baggage: inout BaggageContext, using extractor: Extractor) where Carrier == Extractor.Carrier, Extractor: ExtractorProtocol {
        // TODO: impl
    }

    public func inject<Carrier, Injector>(_ baggage: BaggageContext, into carrier: inout Carrier, using injector: Injector) where Carrier == Injector.Carrier, Injector: InjectorProtocol {
        // TODO: impl
    }

    public func startSpan(
        named operationName: String,
        context: BaggageContext,
        ofKind kind: SpanKind,
        at timestamp: DispatchTime?
    ) -> Span {
        // TODO: parse context, extend existing recorder/segment to use `Baggage`?
        // TODO: map DispatchTime to Timestamp
        // TODO: does kind has any meaning?
        // TODO: what id the context is invalid (BaggageContext does not have a valid one),
        // ^ typically as far XRay is concerned `AWS_XRAY_CONTEXT_MISSING` is used to configure how to handle it
        // TracingInstrument should indicate how to handle that
        // TODO: Here we could look at whether the context contains a parent id to create a subsegment if needed
        beginSegment(name: operationName)
    }
}
