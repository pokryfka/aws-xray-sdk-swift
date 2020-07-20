import AWSXRayRecorder
import Baggage
import Dispatch
import Instrumentation

extension XRayRecorder.Segment: Instrumentation.Span {
    public var operationName: String {
        // TODO: impl
        "test"
    }

    public var kind: SpanKind {
        // TODO: impl
        .internal
    }

    public var status: SpanStatus? {
        // TODO: impl
        get {
            nil
        }
        set(newValue) {}
    }

    public var startTimestamp: DispatchTime {
        // TODO: impl
        DispatchTime.now()
    }

    public var endTimestamp: DispatchTime? {
        // TODO: impl
        nil
    }

    public func end(at timestamp: DispatchTime) {
        // TODO: impl
    }

    public var baggage: BaggageContext {
        // TODO: impl
        BaggageContext()
    }

    public var events: [SpanEvent] {
        // TODO: impl
        [SpanEvent]()
    }

    public func addEvent(_: SpanEvent) {
        // TODO: impl
    }

    public var attributes: SpanAttributes {
        // TODO: impl
        get {
            SpanAttributes()
        }
        set(newValue) {}
    }

    public var isRecording: Bool {
        // TODO: impl
        true
    }

    public var links: [SpanLink] {
        // not supported
        [SpanLink]()
    }

    public func addLink(_: SpanLink) {}
}
