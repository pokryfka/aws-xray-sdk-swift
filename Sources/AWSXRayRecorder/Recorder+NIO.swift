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
import NIO

extension XRayRecorder {
    /// Flushes the emitter in `SwiftNIO` future.
    ///
    /// - Parameter eventLoop: `EventLoop` used to "do the flushing".
    public func flush(on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        waitEmitting()
        // wait for the emitter to send them
        if let nioEmitter = emitter as? XRayNIOEmitter {
            return nioEmitter.flush(on: eventLoop)
        } else {
            let promise = eventLoop.makePromise(of: Void.self)
            emitter.flush { error in
                if let error = error {
                    promise.fail(error)
                } else {
                    promise.succeed(())
                }
            }
            return promise.futureResult
        }
    }
}

extension XRayRecorder {
    /// Creates new segment.
    ///
    /// Records  `Error`.
    ///
    /// - Parameters:
    ///   - name: segment name
    ///   - context: the trace context
    ///   - startTime: start time, defaults to now
    ///   - metadata: segment metadata
    ///   - body: segment body
    @inlinable
    public func segment<T>(name: String, context: TraceContext, startTime: XRayRecorder.Timestamp = .now(),
                           metadata: XRayRecorder.Segment.Metadata? = nil,
                           body: () -> EventLoopFuture<T>) -> EventLoopFuture<T>
    {
        let segment = beginSegment(name: name, context: context, startTime: startTime, metadata: metadata)
        return body().always { result in
            if case Result<T, Error>.failure(let error) = result {
                segment.addError(error)
            }
            segment.end()
        }
    }

    /// Creates new segment.
    ///
    /// Records  `Error`.
    ///
    /// - Parameters:
    ///   - name: segment name
    ///   - baggage: baggage with the trace context
    ///   - startTime: start time, defaults to now
    ///   - metadata: segment metadata
    ///   - body: segment body
    @inlinable
    public func segment<T>(name: String, baggage: BaggageContext, startTime: XRayRecorder.Timestamp = .now(),
                           metadata: XRayRecorder.Segment.Metadata? = nil,
                           body: () -> EventLoopFuture<T>) -> EventLoopFuture<T>
    {
        let segment = beginSegment(name: name, baggage: baggage, startTime: startTime, metadata: metadata)
        return body().always { result in
            if case Result<T, Error>.failure(let error) = result {
                segment.addError(error)
            }
            segment.end()
        }
    }
}

extension EventLoopFuture {
    /// Ends segment when the `EventLoopFuture` is fulfilled, records `.failure`.
    ///
    /// - parameters:
    ///     - segment: the segment to end when the `EventLoopFuture` is fulfilled.
    /// - returns: the current `EventLoopFuture`
    public func endSegment(_ segment: XRayRecorder.Segment) -> EventLoopFuture<Value> {
        whenComplete { result in
            if case Result<Value, Error>.failure(let error) = result {
                segment.addError(error)
            }
            segment.end()
        }
        return self
    }
}

extension EventLoopFuture where Value == Void {
    /// Flushes the recorder.
    ///
    /// - Parameters:
    ///     - recorder: the recorder to flush
    ///     - recover: if false and the future is in error state the error is propagated after flushing.
    /// - Returns: the current `EventLoopFuture`
    public func flush(_ recorder: XRayRecorder, recover: Bool = true) -> EventLoopFuture<Void> {
        map { Result<Value, Error>.success(()) }
            .recover { Result<Value, Error>.failure($0) }
            .flatMap { result in
                recorder.flush(on: self.eventLoop)
                    .flatMapResult { recover ? Result<Value, Error>.success(()) : result }
            }
    }
}
