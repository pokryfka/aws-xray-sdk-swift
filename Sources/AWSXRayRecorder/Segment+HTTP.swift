// TODO: review access level
// TODO: make thread safe?

extension XRayRecorder.Segment {
    enum Namespace: String, Encodable {
        /// AWS SDK calls
        case aws
        /// other downstream calls
        case remote
    }

    /// Use an HTTP block to record details about an HTTP request that your application served (in a segment) or
    /// that your application made to a downstream HTTP API (in a subsegment).
    /// Most of the fields in this object map to information found in an HTTP request and response.
    ///
    /// When you instrument a call to a downstream web api, record a subsegment with information about the HTTP request and response.
    /// X-Ray uses the subsegment to generate an inferred segment for the remote API.
    ///
    /// # References
    /// - [AWS X-Ray segment documents - HTTP request data](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html#api-segmentdocuments-http)
    public struct HTTP: Encodable {
        /// Information about a request.
        public struct Request: Encodable {
            /// The request method. For example, GET.
            var method: String?
            /// The full URL of the request, compiled from the protocol, hostname, and path of the request.
            var url: String?
            /// The user agent string from the requester's client.
            var userAgent: String?
            /// The IP address of the requester.
            /// Can be retrieved from the IP packet's Source Address or, for forwarded requests, from an `X-Forwarded-For` header.
            var clientIP: String?
            /// (segments only) **boolean** indicating that the `client_ip` was read from an `X-Forwarded-For` header and
            /// is not reliable as it could have been forged.
            var xForwardedFor: Bool?
            /// (subsegments only) **boolean** indicating that the downstream call is to another traced service.
            /// If this field is set to `true`, X-Ray considers the trace to be broken until the downstream service uploads a segment with a `parent_id` that
            /// matches the `id` of the subsegment that contains this block.
            var traced: Bool?

            public init(method: String?, url: String?) {
                self.method = method
                self.url = url
            }
        }

        /// Information about a response.
        public struct Response: Encodable {
            /// number indicating the HTTP status of the response.
            var status: UInt?
            /// number indicating the length of the response body in bytes.
            var contentLength: Int?

            public init(status: UInt?, contentLength: Int?) {
                self.status = status
                self.contentLength = contentLength
            }
        }

        var request: Request?
        var response: Response?

        public init(request: Request?, response: Response?) {
            self.request = request
            self.response = response
        }
    }
}

extension XRayRecorder.Segment {
    public func setHTTP(_ http: HTTP) {
        self.http = http
        if let url = http.request?.url {
            namespace = url.contains(".amazonaws.com/") ? .aws : .remote
        }
        if let statusCode = http.response?.status, let error = HTTPError(statusCode: statusCode) {
            setError(error)
        }
    }
}
