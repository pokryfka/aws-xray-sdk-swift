import NIO

extension XRayRecorder {
    @inlinable
    public func segment<T>(name: String, parentId: String? = nil, body: () -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        let segment = beginSegment(name: name, parentId: parentId)
        return body().always { result in
            if case Result<T, Error>.failure(let error) = result {
                segment.setError(error)
            }
            segment.end()
        }
    }

    @inlinable
    public func beginSegment<T>(name: String, parentId: String? = nil, body: (Segment) -> EventLoopFuture<T>) -> EventLoopFuture<(Segment, T)> {
        let segment = beginSegment(name: name, parentId: parentId)
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
    public func subsegment<T>(name: String, body: () -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        let segment = beginSubsegment(name: name)
        return body().always { result in
            if case Result<T, Error>.failure(let error) = result {
                segment.setError(error)
            }
            segment.end()
        }
    }
}
