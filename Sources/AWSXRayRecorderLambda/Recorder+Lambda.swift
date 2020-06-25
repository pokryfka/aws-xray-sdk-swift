import AWSLambdaRuntime
import AWSXRayRecorder
import NIO

extension XRayRecorder {
    public func beginSegment(name: String, context: Lambda.Context) -> Segment {
        let traceHeader = try? XRayRecorder.TraceHeader(string: context.traceID)
        let aws = XRayRecorder.Segment.AWS(requestId: context.requestID)
        traceId = traceHeader?.root ?? TraceID()
        if let parentId = traceHeader?.parentId {
            return beginSubsegment(name: name, parentId: parentId, aws: aws)
        } else {
            return beginSegment(name: name, aws: aws)
        }
    }
}

extension XRayRecorder {
    @inlinable
    public func segment<T>(name: String, context: Lambda.Context, body: (Segment) throws -> T) rethrows -> T
    {
        let segment = beginSegment(name: name, context: context)
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

extension XRayRecorder {
    @inlinable
    public func segment<T>(name: String, context: Lambda.Context, body: () -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        let segment = beginSegment(name: name, context: context)
        return body().always { result in
            if case Result<T, Error>.failure(let error) = result {
                segment.setError(error)
            }
            segment.end()
        }
    }
}
