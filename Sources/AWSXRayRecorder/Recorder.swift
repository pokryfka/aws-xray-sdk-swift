import NIO

// TODO: add callbacks to notify emmiter that there are segments ready to be emmited

/// # References
/// - [Sending trace data to AWS X-Ray](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html)
public class XRayRecorder {
    private let lock = Lock()

    private var _traceId = TraceID()
    private var _segments = [Segment]()

    var traceId: TraceID {
        get { lock.withLock { _traceId } }
        set { lock.withLockVoid { _traceId = newValue } }
    }

    public init() {}

    internal func beginSegment(name: String, parentId: String?, subsegment: Bool,
                               aws: Segment.AWS? = nil, metadata: Segment.Metadata? = nil) -> Segment {
        lock.withLock {
            let newSegment = Segment(
                name: name, traceId: _traceId, parentId: parentId, subsegment: subsegment,
                aws: aws, metadata: metadata
            )
            _segments.append(newSegment)
            return newSegment
        }
    }

    public func beginSegment(name: String, parentId: String? = nil, metadata: Segment.Metadata? = nil) -> Segment {
        beginSegment(name: name, parentId: parentId, subsegment: false, metadata: metadata)
    }

    public func beginSubsegment(name: String, parentId: String, metadata: Segment.Metadata? = nil) -> Segment {
        beginSegment(name: name, parentId: parentId, subsegment: true, metadata: metadata)
    }

    public var allSegments: [Segment] {
        lock.withLock { self._segments }
    }

    public func removeReady() -> [Segment] {
        lock.withLock {
            let allSegments = _segments
            var ready = [Segment]()
            var pending = [Segment]()
            for segment in allSegments {
                if segment.isReady {
                    ready.append(segment)
                } else {
                    pending.append(segment)
                }
            }
            _segments = pending
            return ready
        }
    }
}

extension XRayRecorder.Segment {
    fileprivate var isReady: Bool {
        inProgress != true
    }
}
