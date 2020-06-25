import AWSSDKSwiftCore

public class XRayMiddleware: AWSServiceMiddleware {
    private let recorder: XRayRecorder
    private let name: String

    private var currentSegment: XRayRecorder.Segment?
    private var http = XRayRecorder.Segment.HTTP()
    private var aws = XRayRecorder.Segment.AWS()

    public init(recorder: XRayRecorder, name: String) {
        self.recorder = recorder
        self.name = name
    }

    public func chain(request: AWSRequest) throws -> AWSRequest {
        let segmentName = "\(name)::\(request.operation)"
        currentSegment = recorder.beginSegment(name: segmentName)
        http.request = XRayRecorder.Segment.HTTP.Request(request)
        aws.operation = request.operation
        aws.region = request.region.rawValue
        return request
    }

    public func chain(response: AWSResponse) throws -> AWSResponse {
        http.response = XRayRecorder.Segment.HTTP.Response(response)
        if let requestId = response.headers["x-amz-request-id"] as? String {
            aws.requestId = requestId
        }
        currentSegment?.setHTTP(http)
        currentSegment?.setAWS(aws)
        currentSegment?.end()
        return response
    }
}

private extension XRayRecorder.Segment.HTTP.Request {
    init(_ request: AWSRequest) {
        method = request.httpMethod
        url = request.url.absoluteString
    }
}

private extension XRayRecorder.Segment.HTTP.Response {
    init(_ response: AWSResponse) {
        status = response.status.code
        contentLength = response.body.asString()?.count
    }
}
