import NIO

// TODO: document

// TODO: expose group provider intsead?

extension XRayRecorder {
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
    public func segment<T>(name: String, parentId: Segment.ID? = nil, metadata: Segment.Metadata? = nil,
                           body: () -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        let segment = beginSegment(name: name, parentId: parentId, metadata: metadata)
        return body().always { result in
            if case Result<T, Error>.failure(let error) = result {
                segment.setError(error)
            }
            segment.end()
        }
    }

    // TODO: hopefully there will be a better way to pass the context, per https://github.com/slashmo/gsoc-swift-tracing/issues/48

    @inlinable
    public func beginSegment<T>(name: String, parentId: Segment.ID? = nil, metadata: Segment.Metadata? = nil,
                                body: (Segment) -> EventLoopFuture<T>) -> EventLoopFuture<(Segment, T)> {
        let segment = beginSegment(name: name, parentId: parentId, metadata: metadata)
        return body(segment)
            .always { result in
                if case Result<T, Error>.failure(let error) = result {
                    segment.setError(error)
                }
            }
            .map { (segment, $0) }
    }
}

extension XRayRecorder.Segment {
    @inlinable
    public func subsegment<T>(name: String, metadata: XRayRecorder.Segment.Metadata? = nil,
                              body: () -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        let segment = beginSubsegment(name: name, metadata: metadata)
        return body().always { result in
            if case Result<T, Error>.failure(let error) = result {
                segment.setError(error)
            }
            segment.end()
        }
    }
}
