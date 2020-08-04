//===----------------------------------------------------------------------===//
//
// This source file is part of the aws-xray-sdk-swift open source project
//
// Copyright (c) 2020 pokryfka and the aws-xray-sdk-swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Baggage
import Dispatch
import Logging
import NIOConcurrencyHelpers

/// X-Ray tracer.
///
/// `XRayRecorder` allows to create new `XRayRecorder.Segment`s and sends them using provided `XRayEmitter`.
///
/// # References
/// - [AWS X-Ray concepts](https://docs.aws.amazon.com/xray/latest/devguide/xray-concepts.html#xray-concepts-segments)
/// - [Sending trace data to AWS X-Ray](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html)
public class XRayRecorder {
    private let config: Config
    private let logger: Logger

    private let isShutdown = NIOAtomic<Bool>.makeAtomic(value: false)

    private let segmentsLock = ReadWriteLock()
    private var _segments = [Segment.ID: Segment]()

    internal let emitter: XRayEmitter
    private let emitQueue = DispatchQueue(label: "net.pokryfka.xray.recorder.emit.\(String.random32())")
    private let emitGroup = DispatchGroup()

    internal init(emitter: XRayEmitter, logger: Logger, config: Config = Config()) {
        self.config = config
        var logger = logger
        logger.logLevel = config.logLevel
        self.logger = logger
        self.emitter = emitter
    }

    /// Creates an instance of `XRayRecorder`.
    ///
    /// - Parameters:
    ///   - emitter: emitter used to send `XRayRecorder.Segment`s.
    ///   - config: configuration, **overrides** enviromental variables.
    public convenience init(emitter: XRayEmitter, config: Config = Config()) {
        let logger = Logger(label: "xray.recorder.\(String.random32())")
        if !config.enabled {
            // disable the emitter, even if provided, if recording is disabled
            self.init(emitter: XRayNoOpEmitter(), logger: logger, config: config)
        } else {
            self.init(emitter: emitter, logger: logger, config: config)
        }
    }

    internal func beginSegment(name: String, context: TraceContext, baggage: BaggageContext,
                               aws: Segment.AWS? = nil, metadata: Segment.Metadata? = nil) -> Segment
    {
        guard isShutdown.load() == false else {
            logger.warning("Emitter has been shut down")
            return NoOpSegment(id: .init(), name: name, baggage: baggage)
        }
        guard config.enabled, context.isSampled else {
            return NoOpSegment(id: .init(), name: name, baggage: baggage)
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
        let segmentId = Segment.ID()
        let service = Segment.Service(version: config.serviceVersion)
        let subsegment = context.parentId != nil
        let newSegment = Segment(
            id: segmentId, name: name,
            context: context, baggage: baggage,
            subsegment: subsegment,
            service: service,
            aws: aws, metadata: metadata,
            callback: callback
        )
        segmentsLock.withWriterLockVoid { _segments[segmentId] = newSegment }
        return newSegment
    }

    /// Creates new segment.
    ///
    /// - Parameters:
    ///   - name: segment name
    ///   - context: the trace context
    ///   - metadata: segment metadata
    /// - Returns: new segment
    public func beginSegment(name: String, context: TraceContext, metadata: Segment.Metadata? = nil) -> Segment {
        var baggage = BaggageContext()
        baggage.xRayContext = context
        return beginSegment(name: name, context: context, baggage: baggage, metadata: metadata)
    }

    /// Creates new segment.
    ///
    /// Extracts the trace context from the baggage.
    /// Creates new one if the baggage does not contain a valid `XRayContext`.
    ///
    /// Depending on the context missing strategy configuration will log an error or fail if the context is missing.
    ///
    /// - Parameters:
    ///   - name: segment name
    ///   - baggage: baggage with the trace context
    ///   - metadata: segment metadata
    /// - Returns: new segment
    public func beginSegment(name: String, baggage: BaggageContext, metadata: Segment.Metadata? = nil) -> XRayRecorder.Segment {
        if let context = baggage.xRayContext {
            return beginSegment(name: name, context: context, baggage: baggage, metadata: metadata)
        } else {
            switch config.contextMissingStrategy {
            case .runtimeError:
                preconditionFailure("Missing Context")
            case .logError:
                let context = TraceContext(sampled: false)
                logger.error("Missing Context")
                var baggage = baggage
                baggage.xRayContext = context
                return beginSegment(name: name, context: context, baggage: baggage, metadata: metadata)
            }
        }
    }

    internal func waitEmitting() {
        // wait for all the segments to be passed to the emitter
        // TODO: we should pause creating new segments until all current segments are emitted
        // or queue them separatly in case user keep creating segments after flush
        emitGroup.wait()
    }

    /// Flushes the emitter.
    /// May be blocking.
    ///
    /// - Parameter callback: callback with error if the operation failed.
    public func wait(_ callback: ((Error?) -> Void)? = nil) {
        waitEmitting()
        // wait for the emitter to send them
        emitter.flush(callback ?? { _ in })
    }

    /// Flushes the emitter.
    /// May be blocking.
    ///
    /// `XRayRecorder.Segment`s after `shutdown` are **NOT** recorded.
    ///
    /// - Parameter callback: callback with error if the operation failed.
    public func shutdown(_ callback: ((Error?) -> Void)? = nil) {
        isShutdown.store(true)
        wait(callback)
        emitter.shutdown(callback ?? { _ in })
    }

    private func emit(segment id: Segment.ID) {
        // find the segment
        guard let segment = segmentsLock.withWriterLock({ _segments.removeValue(forKey: id) }) else {
            logger.debug("Segment \(id) parent has not been sent")
            return
        }
        do {
            // mark it as emitted and pass responsibility to the emitter to actually do so
            try segment.emit()
            // check if any of its subsegments are in progress and keep them in the recorder
            let subsegments = segment.subsegmentsInProgress()
            logger.debug("Segment \(id) has \(subsegments.count) subsegments inProgress")
            segmentsLock.withWriterLock {
                subsegments.forEach { _segments[$0.id] = $0 }
            }
            // pass the segment (including its subsegments - in progress or not) to the emitter
            emitter.send(segment)
        } catch {
            logger.error("Failed to emit Segment \(id): \(error)")
        }
    }
}
