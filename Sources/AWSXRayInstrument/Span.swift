import AnyCodable
import AWSXRayRecorder
import Baggage
import Dispatch
import Instrumentation

// TODO: compare with https://github.com/awslabs/aws-xray-sdk-with-opentelemetry/blob/master/sdk/src/main/java/com/amazonaws/xray/opentelemetry/tracing/EntitySpan.java

extension XRayRecorder.Segment: Instrumentation.Span {
    public var operationName: String { name }

    public var kind: SpanKind { .internal }

    public var status: SpanStatus? {
        get { nil } // TODO: getter to be removed
        set(newValue) {
            if let status = newValue {
                setStatus(status)
            }
        }
    }

    public func setStatus(_ status: SpanStatus) {
        // TODO: should the status be set just once?
        guard status.cannonicalCode != .ok else { return }
        // note that contrary to what the name may suggest, exceptions are added not set
        setException(message: status.message ?? "\(status.cannonicalCode)", type: "\(status.cannonicalCode)")
    }

    public var startTimestamp: DispatchTime { DispatchTime.now() } // TODO: getter to be removed

    public var endTimestamp: DispatchTime? { nil } // TODO: getter to be removed

    public func end(at timestamp: DispatchTime) {
        end()
    }

    public var baggage: BaggageContext {
        // TODO: make a Segment attribute
        var baggage = BaggageContext()
        baggage.xRayContext = context
        return baggage
    }

    public var events: [SpanEvent] { [SpanEvent]() } // TODO: getter to be removed

    public func addEvent(_ event: SpanEvent) {
        // XRay segment does not have direct Span Event equivalent
        // Arguably the closest match is a subsegment with startTime == endTime (?)
        // TODO: test different approaches, make it configurable
        beginSubsegment(name: event.name, metadata: nil).end()
        // TODO: set Event attributes once interface is refined
        // we can also store it as metadata as in https://github.com/awslabs/aws-xray-sdk-with-opentelemetry/commit/89f941af2b32844652c190b79328f9f783fe60f8
        appendMetadata(AnyEncodable(event), forKey: MetadataKeys.events.rawValue)
    }

    // TODO: map HTTP Span Attributes to XRAy Segment HTTP object (needs to be exposed, currently internal)

    public func setAttribute(_ value: String, forKey key: String) {
        setAnnotation(value, forKey: key)
    }

    public func setAttribute(_ value: [String], forKey key: String) {
        setMetadata(AnyEncodable(value), forKey: "attr_\(key)")
    }

    public func setAttribute(_ value: Int, forKey key: String) {
        setAnnotation(value, forKey: key)
    }

    public func setAttribute(_ value: [Int], forKey key: String) {
        setMetadata(AnyEncodable(value), forKey: "attr_\(key)")
    }

    public func setAttribute(_ value: Double, forKey key: String) {
        setAnnotation(value, forKey: key)
    }

    public func setAttribute(_ value: [Double], forKey key: String) {
        setMetadata(AnyEncodable(value), forKey: "attr_\(key)")
    }

    public func setAttribute(_ value: Bool, forKey key: String) {
        setAnnotation(value, forKey: key)
    }

    public func setAttribute(_ value: [Bool], forKey key: String) {
        setMetadata(AnyEncodable(value), forKey: "attr_\(key)")
    }

    public var isRecording: Bool {
        context.sampled == .sampled
    }

    public var links: [SpanLink] { [SpanLink]() } // TODO: getter to be removed

    public func addLink(_ link: SpanLink) {
        appendMetadata(AnyEncodable(link), forKey: MetadataKeys.links.rawValue)
    }
}

// MARK: -

private enum MetadataKeys: String {
    case events
    case links
}

extension BaggageContext: Encodable {
    public func encode(to encoder: Encoder) throws {
        guard let context = xRayContext else { return }
        var container = encoder.singleValueContainer()
        // TODO: not sure if it makes sense to encode sampling decision
        try container.encode(context.tracingHeader)
    }
}

extension Instrumentation.SpanEvent: Encodable {
    enum CodingKeys: String, CodingKey {
        case name
        // TODO: add attributes and timestamp after their types are updated
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
    }
}

extension Instrumentation.SpanLink: Encodable {
    enum CodingKeys: String, CodingKey {
        case context
        // TODO: add attributes
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(context, forKey: .context)
    }
}
