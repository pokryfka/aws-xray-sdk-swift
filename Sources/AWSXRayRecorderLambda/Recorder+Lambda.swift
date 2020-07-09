import AnyCodable
import AWSLambdaRuntime
import AWSXRayRecorder
import NIO

// TODO: document

extension XRayRecorder {
    private var metadata: Segment.Metadata {
        // TODO: make it configurable?
        let metadataKeys: [AWSLambdaEnv] = [.functionName, .funtionVersion, .memorySizeInMB]
        let metadataKeyValues = zip(metadataKeys, metadataKeys.map(\.value))
            .filter { $0.1 == nil }.map { ($0.0.rawValue, AnyEncodable($0.1)) }
        let dict = Dictionary(uniqueKeysWithValues: metadataKeyValues)
        return ["env": AnyEncodable(dict)]
    }

    public func beginSegment(name: String, context: Lambda.Context) -> Segment {
        let traceHeader = try? XRayRecorder.TraceHeader(string: context.traceID)
        let aws = XRayRecorder.Segment.AWS(region: AWSLambdaEnv.region.value, requestId: context.requestID)
        if let parentId = traceHeader?.parentId {
            return beginSubsegment(name: name, parentId: parentId, aws: aws, metadata: metadata)
        } else {
            return beginSegment(name: name, aws: aws, metadata: metadata)
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
