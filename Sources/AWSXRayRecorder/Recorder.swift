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

import Dispatch
import Logging

// TODO: document

/// # References
/// - [AWS X-Ray concepts](https://docs.aws.amazon.com/xray/latest/devguide/xray-concepts.html#xray-concepts-segments)
/// - [Sending trace data to AWS X-Ray](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html)
public class XRayRecorder {
    private let config: Config

    private lazy var logger = Logger(label: "xray.recorder.\(String.random32())")

    @Synchronized private var traceId = TraceID()
    @Synchronized private var sampled: Bool = true

    private let segmentsLock = ReadWriteLock()
    private var _segments = [Segment.ID: Segment]()

    internal let emitter: XRayEmitter
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

    internal func beginSegment(name: String, parentId: Segment.ID? = nil, subsegment: Bool = false,
                               aws: Segment.AWS? = nil, metadata: Segment.Metadata? = nil) -> Segment {
        guard config.enabled, sampled else {
            return Segment(
                name: name, traceId: traceId, parentId: parentId, subsegment: subsegment,
                aws: aws, metadata: metadata,
                sampled: .notSampled,
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

    // TODO: pass Context including trace id and sampling decision?
    public func beginSegment(name: String, parentId: Segment.ID? = nil,
                             aws: Segment.AWS? = nil, metadata: Segment.Metadata? = nil) -> Segment {
        beginSegment(name: name, parentId: parentId, subsegment: false, aws: aws, metadata: metadata)
    }

    // TODO: pass Context including trace id and sampling decision?
    public func beginSubsegment(name: String, parentId: Segment.ID,
                                aws: Segment.AWS? = nil, metadata: Segment.Metadata? = nil) -> Segment {
        beginSegment(name: name, parentId: parentId, subsegment: true, aws: aws, metadata: metadata)
    }

    public func beginSegment(name: String, context: TraceContext,
                             aws: Segment.AWS? = nil, metadata: Segment.Metadata? = nil) -> Segment {
        // TODO: do not store "current" or "active" traceId, segmentId or sampling decision
        // we do it here only for the sake of XRayMiddleware which is conceptually broken and
        // hopefully will be replaced
        traceId = context.traceId
        sampled = context.sampled.isSampled != false
        if let parentId = context.parentId {
            return beginSegment(name: name, parentId: parentId, subsegment: true, aws: aws, metadata: metadata)
        } else {
            return beginSegment(name: name, aws: aws, metadata: metadata)
        }
    }

    internal func waitEmitting() {
        // wait for all the segments to be passed to the emitter
        // TODO: we should pause creating new segments until all current segments are emitted
        // or queue them separatly in case user keep creating segments after flush
        emitGroup.wait()
    }

    public func wait(_ callback: ((Error?) -> Void)? = nil) {
        waitEmitting()
        // wait for the emitter to send them
        emitter.flush(callback ?? { _ in })
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
