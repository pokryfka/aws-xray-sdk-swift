import AWSXRayRecorder
import Baggage
import Dispatch
import Instrumentation

extension XRayRecorder.Segment: Instrumentation.Span {
    public var operationName: String { name }

    public var kind: SpanKind { .internal }

    public var status: SpanStatus? {
        // TODO: currently only setError() is public, expose Exception type or perhaps overload setError to provide message and type (as String)
        get { nil } // TODO: getter to be removed
        set(newValue) {}
    }

    public var startTimestamp: DispatchTime { DispatchTime.now() } // TODO: getter to be removed

    public var endTimestamp: DispatchTime? { nil } // TODO: getter to be removed

    public func end(at timestamp: DispatchTime) {
        // TODO: expose (currently internal) method to end at specfied time
        // see comment above
        end()
    }

    public var baggage: BaggageContext {
        // TODO: make a Segment attribute
        var baggage = BaggageContext()
        baggage.xRayContext = context
        return baggage

        // TODO: ! important
        // currently the context, based directly on TracingHeader contains traceId and parentId
        // however the id of the Segment itself is separate:
        // ```
        // _context = TraceContext(traceId: traceId, parentId: parentId, sampled: sampled)
        // _id = id
        // ```
        // to propagate the context for the subsegments we would need to create new one
        // with parentId = the segment id
        //
        // in my XRayRecorder.Segment I created `addSubsegment` method - what way the context
        // is propagated to susegment without explicitly passing it to XRayRecorder (`TracingInstrument`
        // how to do the same using OT API?
    }

    public var events: [SpanEvent] { [SpanEvent]() } // TODO: getter to be removed

    public func addEvent(_ event: SpanEvent) {
        // XRay segment does not have direct Span Event equivalent
        // Arguably the closest match is a subsegment with startTime == endTime (?)
        // TODO: test different appraoches, make it configurable
        beginSubsegment(name: event.name, metadata: nil).end()
        // TODO: set Event attributes once interface is refined
        // we can also store it as metadata as in https://github.com/awslabs/aws-xray-sdk-with-opentelemetry/commit/89f941af2b32844652c190b79328f9f783fe60f8
        setMetadata(event)
    }

    public var attributes: SpanAttributes {
        get { SpanAttributes() } // TODO: getter to be removed
        set(attributes) {}
    }

    public var isRecording: Bool { context.sampled == .sampled }

    public var links: [SpanLink] { [SpanLink]() } // TODO: getter to be removed

    public func addLink(_ link: SpanLink) {
        // XRay segment does not have direct Span Link equivalent
        setMetadata(link)
    }
}
