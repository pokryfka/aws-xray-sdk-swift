import AWSXRayRecorder
import Baggage
import Dispatch
import Instrumentation

extension XRayRecorder.Segment: Instrumentation.Span {
    public var operationName: String { name }

    public var kind: SpanKind {
        // TODO: not sure if/how it corresponds to XRay segment
        .internal
    }

    public var status: SpanStatus? {
        // TODO: currently only setError() is public, expose Exception type or perhaps overload setError to provide message and type (as String)
        // TODO: expose errors
        get {
            nil
        }
        set(newValue) {}
    }

    public var startTimestamp: DispatchTime {
        // TODO: not sure if DispatchTime is the best choice here as it uses relative uptime
        // XRayRecorder.Segment internally uses DispatchWallTime,
        // currently it exposes seconds since which used to be internal
        DispatchTime.now()
    }

    public var endTimestamp: DispatchTime? {
        // TODO: see comment above
        nil
    }

    public func end(at timestamp: DispatchTime) {
        // TODO: expose (currently internal) method to end at epecified time
        // see comment above
        end()
    }

    public var baggage: BaggageContext {
        // TODO: impl
        BaggageContext()
    }

    public var events: [SpanEvent] {
        // TODO:
        // XRay segment does not have direct Span Event equivalent;
        // Arguably the closest match is a subsegment with startTime == endTime (?)
        [SpanEvent]()
    }

    public func addEvent(_: SpanEvent) {}

    public var attributes: SpanAttributes {
        get {
            // TODO: expose annotations collection
//            SpanAttributes(self._annotations.mapValues(SpanAttribute.init))
            SpanAttributes()
        }
        set(attributes) {
            attributes.forEach { key, attribute in
                self.setAttribute(attribute, forKey: key)
            }
        }
    }

    public var isRecording: Bool {
        context.sampled == .sampled
    }

    public var links: [SpanLink] {
        // not defined in XRay segment
        [SpanLink]()
    }

    public func addLink(_: SpanLink) {}
}

private extension XRayRecorder.Segment {
    func setAttribute(_ value: SpanAttribute, forKey key: String) {
        switch value {
        case .string(let stringValue):
            setAnnotation(stringValue, forKey: key)
        case .int(let intValue):
            setAnnotation(intValue, forKey: key)
        case .double(let doubleValue):
            // TODO: change AnnotationValue to Double?
            setAnnotation(Float(doubleValue), forKey: key)
        case .bool(let boolValue):
            setAnnotation(boolValue, forKey: key)
        case .stringConvertible(let stringConvertibleValue):
            setAnnotation(String(describing: stringConvertibleValue), forKey: key)
        case .array:
            // TODO: set as metadata?
            break
        }
    }
}
