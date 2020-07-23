import AnyCodable
import AWSXRayRecorder
import Baggage
import Instrumentation

private enum MetadataKeys: String, CaseIterable {
    case events
    case links
}

extension XRayRecorder.Segment {
    func setMetadata(_ value: Instrumentation.SpanEvent) {
        // TODO: this will work for just one event :-)
        // extend metadata interface to let "append" values to a dictionary?
        setMetadata(AnyEncodable(value), forKey: MetadataKeys.events.rawValue)
    }

    func setMetadata(_ value: Instrumentation.SpanLink) {
        // TODO: this will work for just one event :-)
        // extend metadata interface to let "append" values to a dictionary?
        setMetadata(AnyEncodable(value), forKey: MetadataKeys.links.rawValue)
    }
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
