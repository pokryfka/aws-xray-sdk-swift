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
    /// - Parameters:
    ///   - name: segment name
    ///   - context: the trace context
    ///   - metadata: segment metadata
    ///   - body: segment body
    @inlinable
    public func segment<T>(name: String, context: TraceContext, metadata: Segment.Metadata? = nil,
                           body: () -> EventLoopFuture<T>) -> EventLoopFuture<T>
    {
        let segment = beginSegment(name: name, context: context, metadata: metadata)
        return body().always { result in
            if case Result<T, Error>.failure(let error) = result {
                segment.addError(error)
            }
            segment.end()
        }
    }
}
