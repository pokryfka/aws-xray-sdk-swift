extension XRayRecorder {
    @inlinable
    @discardableResult
    public func segment<T>(name: String, parentId: String? = nil, body: (Segment) throws -> T)
        rethrows -> T
    {
        let segment = beginSegment(name: name, parentId: parentId)
        defer {
            segment.end()
        }
        do {
            return try body(segment)
        } catch {
            segment.setError(error)
            throw error
        }
    }
}

extension XRayRecorder.Segment {
    @inlinable
    @discardableResult
    public func subsegment<T>(name: String, body: (XRayRecorder.Segment) throws -> T) rethrows -> T {
        let segment = beginSubsegment(name: name)
        defer {
            segment.end()
        }
        do {
            return try body(segment)
        } catch {
            segment.setError(error)
            throw error
        }
    }
}
