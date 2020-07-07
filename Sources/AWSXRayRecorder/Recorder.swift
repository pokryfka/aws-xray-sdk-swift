import Dispatch
import Logging
import NIO

// TODO: document

/// # References
/// - [Sending trace data to AWS X-Ray](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html)
public class XRayRecorder {
    private let config = Config()

    private lazy var logger = Logger(label: "net.pokryfka.xray_recorder.recorder")

    @Synchronized var traceId = TraceID()

    private let segmentsLock = ReadWriteLock()
    private var _segments = [Segment.ID: Segment]()
    internal var segments: [Segment] { segmentsLock.withReaderLock { Array(self._segments.values) } }

    private let emitter: XRayEmitter
    private let emitQueue = DispatchQueue(label: "net.pokryfka.xray_recorder.recorder.emit") // TODO: unique name?
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
        let callback: Segment.Callback = { [weak self] id, state in
            guard let self = self else { return }
            guard case .ended = state else { return }
            self.emitGroup.enter()
            self.emitQueue.async {
                self.emit(segment: id)
                self.emitGroup.leave()
            }
        }
        let newSegment = Segment(
            name: name, traceId: traceId, parentId: parentId, subsegment: subsegment,
            aws: aws, metadata: metadata,
            callback: callback
        )
        let segmentId = newSegment.id
        segmentsLock.withWriterLockVoid { _segments[segmentId] = newSegment }
        return newSegment
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

    private func emit(segment id: Segment.ID) {
        // find the segment
        guard let segment = segmentsLock.withWriterLock({ _segments.removeValue(forKey: id) }) else {
            logger.debug("Segment \(id) parent has not been sent")
            return
        }
        // mark it as emitted and pass responsibility to the emitter to actually do so
        do {
            try segment.emit()
        } catch {
            logger.error("Failed to emit Segment \(id): \(error)")
        }
        // check if any of its subsegments are in progress and keep them in the recorder
        let subsegments = segment.subsegmentsInProgress()
        logger.debug("Segment \(id) has \(subsegments.count) subsegments in progress")
        subsegments.forEach { _segments[$0.id] = $0 }
        // pass if the the emitter
        logger.debug("Emitting segment \(id)...")
        emitter.send(segment)
    }
}
