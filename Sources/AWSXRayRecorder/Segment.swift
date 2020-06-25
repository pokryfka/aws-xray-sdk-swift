import AnyCodable
import Foundation

extension XRayRecorder {
    enum SegmentError: Error {
        case invalidID(String)
        // case alreadyEmitted
    }

    /// A segment records tracing information about a request that your application serves.
    /// At a minimum, a segment records the name, ID, start time, trace ID, and end time of the request.
    ///
    /// # References
    /// - [AWS X-Ray segment documents](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html)
    public class Segment: Encodable {
        enum AnnotationValue {
            case string(String)
            case int(Int)
            case float(Float)
            case bool(Bool)
        }

        enum SegmentType: String, Encodable {
            case subsegment
        }

        /// An object with information about your application.
        struct Service: Encodable {
            /// A string that identifies the version of your application that served the request.
            let version: String
        }

        struct Exception: Encodable {
            /// A 64-bit identifier for the exception, unique among segments in the same trace, in **16 hexadecimal digits**.
            let id: String
            /// The exception message.
            var message: String?

            // TODO: other optional attributes
        }

        /// Segments and subsegments can include an annotations object containing one or more fields that
        /// X-Ray indexes for use with filter expressions.
        /// Fields can have string, number, or Boolean values (no objects or arrays).
        /// X-Ray indexes up to 50 annotations per trace.
        ///
        /// Keys must be alphanumeric in order to work with filters. Underscore is allowed. Other symbols and whitespace are not allowed.
        typealias Annotations = [String: AnnotationValue]

        /// Segments and subsegments can include a metadata object containing one or more fields with values of any type, including objects and arrays.
        /// X-Ray does not index metadata, and values can be any size, as long as the segment document doesn't exceed the maximum size (64 kB).
        /// You can view metadata in the full segment document returned by the BatchGetTraces API.
        /// Field keys (debug in the following example) starting with `AWS.` are reserved for use by AWS-provided SDKs and clients.
        public typealias Metadata = [String: AnyEncodable]

        internal let lock = Lock()

        // MARK: Required Segment Fields

        /// The logical name of the service that handled the request, up to **200 characters**.
        /// For example, your application's name or domain name.
        /// Names can contain Unicode letters, numbers, and whitespace, and the following symbols: _, ., :, /, %, &, #, =, +, \, -, @
        let name: String

        /// A 64-bit identifier for the segment, unique among segments in the same trace, in **16 hexadecimal digits**.
        let id: String

        /// A unique identifier that connects all segments and subsegments originating from a single client request.
        ///
        /// # Trace ID Format
        /// A trace_id consists of three numbers separated by hyphens.
        ///
        /// For example, 1-58406520-a006649127e371903a2de979. This includes:
        /// - The version number, that is, 1.
        /// - The time of the original request, in Unix epoch time, in **8 hexadecimal digits**. For example, 10:00AM December 1st, 2016 PST in epoch time is 1480615200 seconds, or 58406520 in hexadecimal digits.
        ///  - A 96-bit identifier for the trace, globally unique, in **24 hexadecimal digits**.
        ///
        /// # Trace ID Security
        /// Trace IDs are visible in response headers. Generate trace IDs with a secure random algorithm to ensure that attackers cannot calculate future trace IDs and send requests with those IDs to your application.
        ///
        /// # Subsegment
        /// Required only if sending a subsegment separately.
        let traceId: TraceID

        /// **number** that is the time the segment was created, in floating point seconds in epoch time.
        /// For example, 1480615200.010 or 1.480615200010E9.
        /// Use as many decimal places as you need. Microsecond resolution is recommended when available.
        let startTime: Double

        /// **number** that is the time the segment was closed.
        /// For example, 1480615200.090 or 1.480615200090E9.
        /// Specify either an end_time or in_progress.
        private(set) var endTime: Double? {
            didSet {
                guard oldValue != endTime else { return }
                inProgress = endTime == nil ? true : nil
            }
        }

        /// **boolean**, set to true instead of specifying an end_time to record that a segment is started, but is not complete.
        /// Send an in-progress segment when your application receives a request that will take a long time to serve, to trace the request receipt.
        /// When the response is sent, send the complete segment to overwrite the in-progress segment.
        /// Only send one complete segment, and one or zero in-progress segments, per request.
        private(set) var inProgress: Bool?

        // MARK: Required Subsegment Fields

        /// Required only if sending a subsegment separately.
        let type: SegmentType?

        // MARK: Optional Segment Fields

        /// A subsegment ID you specify if the request originated from an instrumented application.
        /// The X-Ray SDK adds the parent subsegment ID to the tracing header for downstream HTTP calls.
        /// In the case of nested subsguments, a subsegment can have a segment or a subsegment as its parent.
        ///
        /// # Subsegment
        /// Required only if sending a subsegment separately.
        /// In the case of nested subsegments, a subsegment can have a segment or a subsegment as its parent.
        let parentId: String?

        /// An object with information about your application.
        private var _service: Service?

        /// A string that identifies the user who sent the request.
        private var _user: String?

        /// The type of AWS resource running your application.
        private var _origin: Origin?

        /// http objects with information about the original HTTP request.
        private var _http: HTTP?

        /// aws object with information about the AWS resource on which your application served the request
        private var _aws: AWS?

        /// **boolean** indicating that a client error occurred (response status code was 4XX Client Error).
        private var error: Bool?
        /// **boolean** indicating that a request was throttled (response status code was 429 Too Many Requests).
        private var throttle: Bool?
        /// **boolean** indicating that a server error occurred (response status code was 5XX Server Error).
        private var fault: Bool?
        /// the exception that caused the error.
        private var cause: Exception?

        /// annotations object with key-value pairs that you want X-Ray to index for search.
        private var annotations: Annotations?

        /// metadata object with any additional data that you want to store in the segment.
        private var metadata: Metadata?

        /// **array** of subsegment objects.
        private var subsegments: [Segment]?

        // MARK: Optional Subsegment Fields

        /// `aws` for AWS SDK calls; `remote` for other downstream calls.
        private var namespace: Namespace?

        /// **array** of subsegment IDs that identifies subsegments with the same parent that completed prior to this subsegment.
        private var precursorIDs: [String]?

        init(
            name: String, traceId: TraceID, parentId: String?, subsegment: Bool,
            service: Service? = nil, user: String? = nil,
            origin _: Origin? = nil, http: HTTP? = nil, aws: AWS? = nil,
            annotations: Annotations? = nil, metadata: Metadata? = nil
        ) {
            self.name = name
            id = Self.generateId()
            self.traceId = traceId
            startTime = Date().timeIntervalSince1970
            inProgress = true
            self.parentId = parentId
            type = subsegment && parentId != nil ? .subsegment : nil
            _service = service
            _user = user
            _http = http
            _aws = aws
            self.annotations = annotations
            self.metadata = metadata
        }

        enum CodingKeys: String, CodingKey {
            case name
            case id
            case traceId = "trace_id"
            case startTime = "start_time"
            case endTime = "end_time"
            case inProgress = "in_progress"
            case type
            case parentId = "parent_id"
            case _service = "service"
            case _user = "user"
            case _origin = "origin"
            case _http = "http"
            case _aws = "aws"
            case error, throttle, fault, cause
            case annotations, metadata
            case subsegments
            case namespace
            case precursorIDs = "precursor_ids"
        }
    }
}

// MARK: End time

extension XRayRecorder.Segment {
    /// Updates `endTime` of the Segment, ends subsegments if not ended.
    public func end() {
        let now = Date().timeIntervalSince1970
        end(date: now)
    }

    func end(date: Double) {
        lock.withLockVoid {
            if endTime == nil {
                endTime = date
            }
            let date = endTime ?? date
            subsegments?.forEach { $0.end(date: date) }
        }
    }
}

// MARK: HTTP request data

extension XRayRecorder.Segment {
    public func setHTTP(_ http: HTTP) {
        lock.withLock {
            _http = http
            if type == .some(.subsegment), let url = http.request?.url {
                namespace = url.contains(".amazonaws.com/") ? .aws : .remote
            }
            if let code = http.response?.status {
                if code >= 400, code < 600 {
                    error = true
                }
                if code == 429 {
                    throttle = true
                }
                if code >= 500, code < 600 {
                    fault = true
                }
            }
        }
    }
}

// MARK: AWS resource data

extension XRayRecorder.Segment {
    func setAWS(_ aws: AWS) {
        lock.withLock {
            _aws = aws
        }
    }
}

// MARK: Errors and exceptions

extension XRayRecorder.Segment {
    public func setError(_ error: Error) {
        let exception = Exception(
            id: XRayRecorder.Segment.generateId(),
            message: "\(error)"
        )
        lock.withLockVoid {
            self.error = true
            cause = exception
        }
    }
}

// MARK: Annotations and Metadata

extension XRayRecorder.Segment {
    func setAnnotations(_ newElements: Annotations) {
        lock.withLock {
            if (annotations?.count ?? 0) > 0 {
                for (k, v) in newElements {
                    annotations?.updateValue(v, forKey: k)
                }
            } else {
                annotations = newElements
            }
        }
    }

    public func setAnnotation(_ key: String, value: Bool) {
        setAnnotations([key: .bool(value)])
    }

    public func setAnnotation(_ key: String, value: Int) {
        setAnnotations([key: .int(value)])
    }

    public func setAnnotation(_ key: String, value: Float) {
        setAnnotations([key: .float(value)])
    }

    public func setAnnotation(_ key: String, value: String) {
        setAnnotations([key: .string(value)])
    }

    public func setMetadata(_ newElements: Metadata) {
        lock.withLock {
            if (metadata?.count ?? 0) > 0 {
                for (k, v) in newElements {
                    metadata?.updateValue(v, forKey: k)
                }
            } else {
                metadata = newElements
            }
        }
    }
}

extension XRayRecorder.Segment.AnnotationValue: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .float(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        }
    }
}

// MARK: Subsegments

extension XRayRecorder.Segment {
    public func beginSubsegment(name: String) -> XRayRecorder.Segment {
        lock.withLock {
            let newSegment = XRayRecorder.Segment(
                name: name, traceId: traceId, parentId: id, subsegment: true
            )
            if (subsegments?.count ?? 0) > 0 {
                subsegments?.append(newSegment)
            } else {
                subsegments = [newSegment]
            }
            return newSegment
        }
    }
}

// MARK: Id

extension XRayRecorder.Segment {
    /// - returns: A 64-bit identifier for the segment, unique among segments in the same trace, in 16 hexadecimal digits.
    static func generateId() -> String {
        String(format: "%llx", UInt64.random(in: UInt64.min ... UInt64.max) | 1 << 63)
    }
}

// MARK: Validation

extension XRayRecorder.Segment {
    static func validateId(_ string: String) throws -> String {
        let invalidCharacters = CharacterSet(charactersIn: "abcdef0123456789").inverted
        guard
            string.count == 16,
            string.rangeOfCharacter(from: invalidCharacters) == nil
        else {
            throw XRayRecorder.SegmentError.invalidID(string)
        }
        return string
    }

    // TODO: validate name
}
