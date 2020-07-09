import Dispatch
import Logging
import NIO

// TODO: document

/// # References
/// - [Sending trace data to AWS X-Ray](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html)
public class XRayRecorder {
    private let config: Config

    private lazy var logger = Logger(label: "xray.recorder.\(String.random32())")

    @Synchronized public var traceId = TraceID()

    private let segmentsLock = ReadWriteLock()
    private var _segments = [Segment.ID: Segment]()

    private let emitter: XRayEmitter
    private let emitQueue = DispatchQueue(label: "net.pokryfka.xray.recorder.emit.\(String.random32())")
    private let emitGroup = DispatchGroup()

    public init(emitter: XRayEmitter, config: Config = Config()) {
        self.config = config
        if !config.enabled {
            self.emitter = XRayNoOpEmitter()
        } else {
            self.emitter = emitter
        }
        logger.logLevel = config.logLevel
    }

    public convenience init(config: Config = Config(), eventLoopGroup: EventLoopGroup? = nil) {
        if !config.enabled {
            self.init(emitter: XRayNoOpEmitter(), config: config)
        } else {
            do {
                let emitter = try XRayUDPEmitter(config: .init(config), eventLoopGroup: eventLoopGroup)
                self.init(emitter: emitter, config: config)
            } catch {
                preconditionFailure("Failed to create XRayUDPEmitter: \(error)")
            }
        }
    }

    internal func beginSegment(name: String, parentId: String?, subsegment: Bool,
                               aws: Segment.AWS? = nil, metadata: Segment.Metadata? = nil) -> Segment {
        let parentId: Segment.ID? = parentId.flatMap(Segment.ID.init)
        guard config.enabled else {
            return Segment(
                name: name, traceId: traceId, parentId: parentId, subsegment: subsegment,
                aws: aws, metadata: metadata,
                callback: nil
            )
        }

        let callback: Segment.StateChangeCallback = { [weak self] id, state in
            guard let self = self else { return }
            self.logger.info("Segment \(id) \(state)")
            guard case .ended = state else { return }
            self.emitGroup.enter()
            self.emitQueue.async {
                self.emit(segment: id)
                self.emitGroup.leave()
            }
        }
        let newSegment = Segment(
            name: name, traceId: traceId, parentId: parentId, subsegment: subsegment,
            service: .init(version: config.serviceVersion),
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

    public func wait() {
        // TODO: tests tests tests
        // TODO: we should probably pause creating new segments until all current segments are emitted
        // or queue them separatly
        // wait for all the segments to be passed to the emitter
        emitGroup.wait()
        // wait for the emitter to send them
        emitter.flush { _ in }
    }

    public func flush(on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        // wait for all the segments to be passed to the emitter
        emitGroup.wait()
        // wait for the emitter to send them
        if let nioEmitter = emitter as? XRayNIOEmitter {
            // TODO: log error
            return nioEmitter.flush(on: eventLoop)
        } else {
            return eventLoop.submit {
                // TODO: pass error
                self.emitter.flush { _ in }
            }
        }
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
        logger.debug("Segment \(id) has \(subsegments.count) subsegments \(Segment.State.inProgress)")
        subsegments.forEach { _segments[$0.id] = $0 }
        // pass if the the emitter
        emitter.send(segment)
    }
}
