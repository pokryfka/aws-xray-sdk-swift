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

// TODO: document

extension XRayRecorder {
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

extension XRayRecorder.Segment {
    @inlinable
    public func subsegment<T>(name: String, metadata: XRayRecorder.Segment.Metadata? = nil,
                              body: () -> EventLoopFuture<T>) -> EventLoopFuture<T>
    {
        let segment = beginSubsegment(name: name, metadata: metadata)
        return body().always { result in
            if case Result<T, Error>.failure(let error) = result {
                segment.addError(error)
            }
            segment.end()
        }
    }
}
