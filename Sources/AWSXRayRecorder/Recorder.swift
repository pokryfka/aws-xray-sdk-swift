import Dispatch
import Logging
import NIO

// TODO: document

/// # References
/// - [Sending trace data to AWS X-Ray](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html)
public class XRayRecorder {
    private let config = Config()

    private lazy var logger = Logger(label: "net.pokryfka.xray_recorder.recorder")

    private let lock = Lock()

    private var _traceId = TraceID()
    private var _segments = [Segment.ID: Segment]()

    public var traceId: TraceID {
        get { lock.withLock { _traceId } }
        set { lock.withLockVoid { _traceId = newValue } }
    }

    private let emitter: XRayEmitter
    private let emitQueue = DispatchQueue(label: "net.pokryfka.xray_recorder.recorder.emit")
    private let emitGroup = DispatchGroup()

    public init(emitter: XRayEmitter) {
        self.emitter = emitter
        logger.logLevel = config.logLevel
    }

    public init() {
        // TODO: handle failure
        emitter = try! XRayUDPEmitter()
        logger.logLevel = config.logLevel
    }

    deinit {}

    internal func beginSegment(name: String, parentId: String?, subsegment: Bool,
                               aws: Segment.AWS? = nil, metadata: Segment.Metadata? = nil) -> Segment {
        lock.withLock {
            let callback: Segment.Callback = { [weak self] id in
                self?.emitGroup.enter()
                self?.emitQueue.async {
                    self?.emit(segment: id)
                    self?.emitGroup.leave()
                }
            }
            let newSegment = Segment(
                name: name, traceId: _traceId, parentId: parentId, subsegment: subsegment,
                aws: aws, metadata: metadata,
                callback: callback
            )
            let segmentId = newSegment.id
            _segments[segmentId] = newSegment
            return newSegment
        }
    }

    public func beginSegment(name: String, parentId: String? = nil,
                             aws: Segment.AWS? = nil, metadata: Segment.Metadata? = nil) -> Segment {
        beginSegment(name: name, parentId: parentId, subsegment: false, aws: aws, metadata: metadata)
    }

    public func beginSubsegment(name: String, parentId: String,
                                aws: Segment.AWS? = nil, metadata: Segment.Metadata? = nil) -> Segment {
        beginSegment(name: name, parentId: parentId, subsegment: true, aws: aws, metadata: metadata)
    }

    public func flush() /* -> EventLoopFuture<Void> */ {
        // TODO: provide a non blocking method with a future
        // wait for all the segments to be passed to the emitter
        emitGroup.wait()
        // wait for the emitter to send them
        emitter.flush { _ in }
    }

    public var allSegments: [Segment] {
        lock.withLock { Array(self._segments.values) }
    }

//    public func removeReady() -> [Segment] {
//        lock.withLock {
//            let allSegments = _segments
//            var ready = [Segment]()
//            var pending = [Segment]()
//            for segment in allSegments {
//                if segment.isReady {
//                    ready.append(segment)
//                } else {
//                    pending.append(segment)
//                }
//            }
//            _segments = pending
//            return ready
//        }
//    }

    private func emit(segment id: Segment.ID) {
        guard let segment = lock.withLock({ _segments.removeValue(forKey: id) }) else {
            logger.debug("Segment \(id) parent has not been sent")
            return
        }
        logger.debug("Emitting segment \(id)...")
        emitter.send(segment)
    }
}

// extension XRayRecorder.Segment {
//    fileprivate var isReady: Bool {
//        inProgress != true
//    }
// }
