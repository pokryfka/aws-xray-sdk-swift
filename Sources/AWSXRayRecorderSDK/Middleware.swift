import AWSSDKSwiftCore
import AWSXRayRecorder
import NIOConcurrencyHelpers

// TODO: segment is not ended if reauest failed, see https://github.com/swift-aws/aws-sdk-swift/issues/326
// TODO: match request and response based on `ahc-request-id`, see https://github.com/swift-server/async-http-client/pull/227/files

// WIP: this is likely to be replaced with https://github.com/slashmo/gsoc-swift-tracing/issues/50

public class XRayMiddleware: AWSServiceMiddleware {
    private let lock = Lock()

    private let recorder: XRayRecorder
    private let name: String

    private var currentSegment: XRayRecorder.Segment?
    private var httpRequest: XRayRecorder.Segment.HTTP.Request?
    private var aws: XRayRecorder.Segment.AWS?

    public init(recorder: XRayRecorder, name: String) {
        self.recorder = recorder
        self.name = name
    }

    public func chain(request: AWSRequest) throws -> AWSRequest {
        lock.withLock {
            let segmentName = "\(name)::\(request.operation)"
            currentSegment = recorder.beginSegment(name: segmentName)
            httpRequest = XRayRecorder.Segment.HTTP.Request(request)
            aws = XRayRecorder.Segment.AWS(operation: request.operation,
                                           region: request.region.rawValue)
            return request
        }
    }

    public func chain(response: AWSResponse) throws -> AWSResponse {
        lock.withLock {
            let httpResponse = XRayRecorder.Segment.HTTP.Response(response)
            let http = XRayRecorder.Segment.HTTP(request: httpRequest, response: httpResponse)
            if let requestId = response.headers["x-amz-request-id"] as? String {
                aws?.requestId = requestId
            }
            currentSegment?.setHTTP(http)
            if let aws = aws {
                currentSegment?.setAWS(aws)
            }
            currentSegment?.end()
            currentSegment = nil
            httpRequest = nil
            aws = nil
            return response
        }
    }
}

private extension XRayRecorder.Segment.HTTP.Request {
    init(_ request: AWSRequest) {
        self.init(method: request.httpMethod, url: request.url.absoluteString)
    }
}

private extension XRayRecorder.Segment.HTTP.Response {
    init(_ response: AWSResponse) {
        self.init(status: response.status.code, contentLength: response.body.asString()?.count)
    }
}
