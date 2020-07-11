import AnyCodable

// TODO: document

private typealias SegmentError = XRayRecorder.SegmentError

extension XRayRecorder {
    enum SegmentError: Error {
        case invalidID(String)
        case inProgress
        case alreadyEmitted
    }

    /// A segment records tracing information about a request that your application serves.
    /// At a minimum, a segment records the name, ID, start time, trace ID, and end time of the request.
    ///
    /// # References
    /// - [AWS X-Ray segment documents](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html)
    public class Segment {
        internal struct ID: RawRepresentable, Hashable, Encodable, CustomStringConvertible {
            let rawValue: String
            var description: String { rawValue }
            init?(rawValue: String) {
                guard let id = try? validateId(rawValue) else { return nil }
                self.rawValue = id
            }

            init() { rawValue = String.random64() }
        }

        internal enum State {
            case inProgress
            case ended(Timestamp)
            case emitted(Timestamp)
        }

        internal typealias StateChangeCallback = ((ID, State) -> Void)

        private enum SegmentType: String, Encodable {
            case subsegment
        }

        /// An object with information about your application.
        internal struct Service: Encodable {
            /// A string that identifies the version of your application that served the request.
            let version: String
        }

        /// Segments and subsegments can include an annotations object containing one or more fields that
        /// X-Ray indexes for use with filter expressions.
        /// Fields can have string, number, or Boolean values (no objects or arrays).
        /// X-Ray indexes up to 50 annotations per trace.
        ///
        /// Keys must be alphanumeric in order to work with filters. Underscore is allowed. Other symbols and whitespace are not allowed.
        internal typealias Annotations = [String: AnnotationValue]

        /// Segments and subsegments can include a metadata object containing one or more fields with values of any type, including objects and arrays.
        /// X-Ray does not index metadata, and values can be any size, as long as the segment document doesn't exceed the maximum size (64 kB).
        /// You can view metadata in the full segment document returned by the BatchGetTraces API.
        /// Field keys (debug in the following example) starting with `AWS.` are reserved for use by AWS-provided SDKs and clients.
        public typealias Metadata = [String: AnyEncodable]

        private let lock = ReadWriteLock()

        private let callback: StateChangeCallback?

        private var _state = State.inProgress {
            didSet {
                guard oldValue != _state else { return }
                if case .ended(let timestamp) = _state {
                    endTime = timestamp
                    inProgress = nil
                }
                callback?(id, _state)
            }
        }

        private var state: State { lock.withReaderLock { _state } }

        // MARK: Required Segment Fields

        /// A 64-bit identifier for the segment, unique among segments in the same trace, in **16 hexadecimal digits**.
        internal let id: ID

        /// The logical name of the service that handled the request, up to **200 characters**.
        /// For example, your application's name or domain name.
        /// Names can contain Unicode letters, numbers, and whitespace, and the following symbols: _, ., :, /, %, &, #, =, +, \, -, @
        private let name: String

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
        private let traceId: TraceID

        /// **number** that is the time the segment was created, in floating point seconds in epoch time.
        /// For example, 1480615200.010 or 1.480615200010E9.
        /// Use as many decimal places as you need. Microsecond resolution is recommended when available.
        private let startTime: Timestamp

        /// **number** that is the time the segment was closed.
        /// For example, 1480615200.090 or 1.480615200090E9.
        /// Specify either an end_time or in_progress.
        private var endTime: Timestamp?

        /// **boolean**, set to true instead of specifying an end_time to record that a segment is started, but is not complete.
        /// Send an in-progress segment when your application receives a request that will take a long time to serve, to trace the request receipt.
        /// When the response is sent, send the complete segment to overwrite the in-progress segment.
        /// Only send one complete segment, and one or zero in-progress segments, per request.
        private var inProgress: Bool? = true

        // MARK: Required Subsegment Fields

        /// Required only if sending a subsegment separately.
        private let type: SegmentType?

        // MARK: Optional Segment Fields

        /// A subsegment ID you specify if the request originated from an instrumented application.
        /// The X-Ray SDK adds the parent subsegment ID to the tracing header for downstream HTTP calls.
        /// In the case of nested subsguments, a subsegment can have a segment or a subsegment as its parent.
        ///
        /// # Subsegment
        /// Required only if sending a subsegment separately.
        /// In the case of nested subsegments, a subsegment can have a segment or a subsegment as its parent.
        private let parentId: ID?

        /// An object with information about your application.
        private let service: Service?

        /// A string that identifies the user who sent the request.
        private let user: String?

        /// The type of AWS resource running your application.
        @Synchronized internal var origin: Origin?

        /// http objects with information about the original HTTP request.
        @Synchronized internal var http: HTTP?

        /// aws object with information about the AWS resource on which your application served the request
        @Synchronized internal var aws: AWS?

        /// **boolean** indicating that a client error occurred (response status code was 4XX Client Error).
        private var _error: Bool?
        /// **boolean** indicating that a request was throttled (response status code was 429 Too Many Requests).
        private var _throttle: Bool?
        /// **boolean** indicating that a server error occurred (response status code was 5XX Server Error).
        private var _fault: Bool?
        /// the exception that caused the error.
        private var _cause: Exception?

        /// annotations object with key-value pairs that you want X-Ray to index for search.
        private var _annotations: Annotations

        /// metadata object with any additional data that you want to store in the segment.
        private var _metadata: Metadata

        /// **array** of subsegment objects.
        private var _subsegments: [Segment] = [Segment]()

        // MARK: Optional Subsegment Fields

        /// `aws` for AWS SDK calls; `remote` for other downstream calls.
        @Synchronized internal var namespace: Namespace?

        /// **array** of subsegment IDs that identifies subsegments with the same parent that completed prior to this subsegment.
        private let precursorIDs: [String]? = nil

        init(
            id: ID = ID(),
            name: String, traceId: TraceID, startTime: Timestamp = Timestamp(),
            parentId: ID? = nil, subsegment: Bool = false,
            service: Service? = nil, user: String? = nil,
            origin: Origin? = nil, http: HTTP? = nil, aws: AWS? = nil,
            annotations: Annotations? = nil, metadata: Metadata? = nil,
            callback: StateChangeCallback? = nil
        ) {
            self.id = id
            self.name = name
            self.traceId = traceId
            self.startTime = startTime
            self.parentId = parentId
            // TODO: should we check if parentId is different than id?
            type = subsegment && parentId != nil ? .subsegment : nil
            self.service = service
            self.user = user
            self.origin = origin
            self.http = http
            self.aws = aws
            _annotations = annotations ?? Annotations()
            _metadata = metadata ?? Metadata()
            self.callback = callback
        }
    }
}

// MARK: - State

extension XRayRecorder.Segment.State: Equatable {
    static func == (lhs: XRayRecorder.Segment.State, rhs: XRayRecorder.Segment.State) -> Bool {
        switch (lhs, rhs) {
        case (.inProgress, .inProgress):
            return true
        case (.ended(let lhs), .ended(let rhs)):
            return lhs == rhs
        case (.emitted(let lhs), .emitted(let rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
}

extension XRayRecorder.Segment.State: CustomStringConvertible {
    var description: String {
        switch self {
        case .inProgress:
            return "inProgress"
        case .ended(let timestamp):
            return "ended @ \(timestamp.secondsSinceEpoch)"
        case .emitted(let timestamp):
            return "emitted @ \(timestamp.secondsSinceEpoch)"
        }
    }
}

extension XRayRecorder.Segment.State {
    var inProgress: Bool {
        switch self {
        case .inProgress:
            return true
        default:
            return false
        }
    }
}

extension XRayRecorder.Segment {
    /// Updates `endTime` of the Segment.
    public func end() {
        end(Timestamp())
    }

    internal func end(_ timestamp: Timestamp) {
        lock.withWriterLockVoid {
            guard case .inProgress = _state else {
                return
            }
            // TODO: check that the value is after startTime
            _state = .ended(timestamp)
        }
    }

    internal func emit() throws {
        try lock.withWriterLockVoid {
            if case .emitted = _state {
                throw SegmentError.alreadyEmitted
            }
            // for now we limit sending of in-progress segments to subsegments
            // to make sure that their parent was already emitted
            if case .inProgress = _state {
                throw SegmentError.inProgress
            }
            _state = .emitted(Timestamp())
        }
    }
}

// MARK: - Subsegments

extension XRayRecorder.Segment {
    public func beginSubsegment(name: String, metadata: XRayRecorder.Segment.Metadata? = nil) -> XRayRecorder.Segment {
        lock.withWriterLock {
            let newSegment = XRayRecorder.Segment(
                name: name, traceId: self.traceId, parentId: self.id, subsegment: true,
                metadata: metadata,
                callback: self.callback
            )
            _subsegments.append(newSegment)
            return newSegment
        }
    }

    internal func subsegmentsInProgress() -> [XRayRecorder.Segment] {
        lock.withReaderLock {
            guard _subsegments.isEmpty == false else {
                return [XRayRecorder.Segment]()
            }
            // TODO: make it nicer
            var segmentsInProgess = [XRayRecorder.Segment]()
            for segment in _subsegments {
                // add subsegment if in progress
                if segment.state.inProgress {
                    segmentsInProgess.append(segment)
                }
                // otherwise check if any of its subsegments are in progress
                else {
                    segmentsInProgess.append(contentsOf: segment.subsegmentsInProgress())
                }
            }
            return segmentsInProgess
        }
    }
}

// MARK: - Errors and exceptions

extension XRayRecorder.Segment {
    internal enum HTTPError: Error {
        /// client error occurred (response status code was 4XX Client Error)
        case client(statusCode: UInt, cause: Exception?)
        /// request was throttled (response status code was 429 Too Many Requests)
        case throttle(cause: Exception?)
        /// server error occurred (response status code was 5XX Server Error)
        case server(statusCode: UInt, cause: Exception?)

        init?(statusCode: UInt) {
            switch statusCode {
            case 429:
                self = .throttle(cause: nil)
            case 400 ..< 500:
                self = .client(statusCode: statusCode, cause: nil)
            case 500 ..< 600:
                self = .server(statusCode: statusCode, cause: nil)
            default:
                return nil
            }
        }

        var cause: Exception? {
            switch self {
            case .client(_, let cause):
                return cause
            case .throttle(let cause):
                return cause
            case .server(_, let cause):
                return cause
            }
        }
    }

    internal struct Exception: Encodable {
        /// A 64-bit identifier for the exception, unique among segments in the same trace, in **16 hexadecimal digits**.
        let id: String
        /// The exception message.
        var message: String?

        // TODO: other optional attributes
    }
}

extension XRayRecorder.Segment {
    public func setError(_ error: Error) {
        let exception = Exception(
            id: String.random64(),
            message: "\(error)"
        )
        lock.withWriterLockVoid {
            self._error = true
            _cause = exception
        }
    }

    internal func setError(_ httpError: HTTPError) {
        lock.withWriterLockVoid {
            _error = true
            _cause = httpError.cause
            switch httpError {
            case .throttle:
                _throttle = true
            case .server:
                _fault = true
            default:
                break
            }
        }
    }
}

// MARK: - Annotations and Metadata

extension XRayRecorder.Segment {
    internal enum AnnotationValue {
        case string(String)
        case int(Int)
        case float(Float)
        case bool(Bool)
    }

    private func setAnnotations(_ newElements: Annotations) {
        lock.withWriterLockVoid {
            for (k, v) in newElements {
                _annotations.updateValue(v, forKey: k)
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
        lock.withWriterLockVoid {
            for (k, v) in newElements {
                _metadata.updateValue(v, forKey: k)
            }
        }
    }
}

// MARK: - Encodable

extension XRayRecorder.Segment: Encodable {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case traceId = "trace_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case inProgress = "in_progress"
        case type
        case parentId = "parent_id"
        case service
        case user
        case origin
        case http
        case aws
        case _error = "error"
        case _throttle = "throttle"
        case _fault = "fault"
        case _cause = "cause"
        case _annotations = "annotations"
        case _metadata = "metadata"
        case _subsegments = "subsegments"
        case namespace
        case precursorIDs = "precursor_ids"
    }

    public func encode(to encoder: Encoder) throws {
        try lock.withReaderLockVoid {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encode(traceId, forKey: .traceId)
            try container.encode(startTime, forKey: .startTime)
            // encode either endTime or inProgress
            if let endTime = endTime {
                try container.encode(endTime, forKey: .endTime)
            } else if let inProgress = inProgress {
                try container.encode(inProgress, forKey: .inProgress)
            }
            // do not encode nil values
            if let type = type {
                try container.encode(type, forKey: .type)
            }
            if let parentId = parentId {
                try container.encode(parentId, forKey: .parentId)
            }
            if let service = service {
                try container.encode(service, forKey: .service)
            }
            if let user = user {
                try container.encode(user, forKey: .user)
            }
            if let origin = origin {
                try container.encode(origin, forKey: .origin)
            }
            if let http = http {
                try container.encode(http, forKey: .http)
            }
            if let aws = aws {
                try container.encode(aws, forKey: .aws)
            }
            // TODO: create Encodable exception type with throttle, fault, cause?
            if let error = _error {
                try container.encode(error, forKey: ._error)
            }
            if let throttle = _throttle {
                try container.encode(throttle, forKey: ._throttle)
            }
            if let fault = _fault {
                try container.encode(fault, forKey: ._fault)
            }
            if let cause = _cause {
                try container.encode(cause, forKey: ._cause)
            }
            if let namespace = namespace {
                try container.encode(namespace, forKey: .namespace)
            }
            if let precursorIDs = precursorIDs {
                try container.encode(precursorIDs, forKey: .precursorIDs)
            }
            // do not encode empty arrays
            if _annotations.isEmpty == false {
                try container.encode(_annotations, forKey: ._annotations)
            }
            if _metadata.isEmpty == false {
                // do not throw if encoding of AnyCodable failed
                try? container.encode(_metadata, forKey: ._metadata)
            }
            if _subsegments.isEmpty == false {
                try container.encode(_subsegments, forKey: ._subsegments)
            }
        }
    }
}

extension XRayRecorder.Segment.AnnotationValue: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .float(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        }
    }
}

// MARK: - Validation

// TODO: remove dependency on Foundation
import struct Foundation.CharacterSet

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
