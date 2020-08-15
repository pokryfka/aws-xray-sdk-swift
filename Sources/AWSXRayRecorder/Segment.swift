//===----------------------------------------------------------------------===//
//
// This source file is part of the aws-xray-sdk-swift open source project
//
// Copyright (c) 2020 pokryfka and the aws-xray-sdk-swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Baggage
import Logging
import NIOHTTP1

extension XRayRecorder {
    enum SegmentError: Error {
        case inProgress
        case backToTheFuture
        case alreadyEnded
        case alreadyEmitted
    }

    /// A segment records tracing information about a request that your application serves.
    ///
    /// At a minimum, a segment records the name, ID, start time, trace ID, and end time of the request.
    ///
    /// # References
    /// - [AWS X-Ray segment documents](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html)
    public class Segment {
        /// A 64-bit identifier in **16 hexadecimal digits**.
        public struct ID: RawRepresentable, Hashable, Encodable, CustomStringConvertible {
            public let rawValue: String
            public var description: String { rawValue }
            public init?(rawValue: String) {
                guard rawValue.count == 16, Float("0x\(rawValue)") != nil else { return nil }
                self.rawValue = rawValue
            }

            /// Creates new `ID`.
            public init() { rawValue = String.random64() }
        }

        internal enum State {
            case inProgress(started: Timestamp)
            case ended(started: Timestamp, ended: Timestamp)
            case emitted(started: Timestamp, ended: Timestamp, emitted: Timestamp)
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

        /// Segments and subsegments can include an `annotations` object containing one or more fields that X-Ray indexes for use with filter expressions.
        /// Fields can have string, number, or Boolean values (no objects or arrays). X-Ray indexes up to 50 annotations per trace.
        ///
        /// Keys must be alphanumeric in order to work with filters. Underscore is allowed. Other symbols and whitespace are not allowed.
        internal enum AnnotationValue: Equatable {
            case string(String)
            case integer(Int)
            case double(Double)
            case bool(Bool)
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

        private let logger: Logger?

        private let lock = ReadWriteLock()

        private let _callback: StateChangeCallback?

        private let _id: ID
        private let _name: String
        private let _context: TraceContext
        private var _state: State {
            didSet {
                guard oldValue != _state else { return }
                _callback?(_id, _state)
            }
        }

        private var state: State { lock.withReaderLock { _state } }

        private let _baggage: BaggageContext

        /// Context baggage containing `XRayContext`.
        public var baggage: BaggageContext { lock.withReaderLock { _baggage } }

        /// Indicates if the segment is recording information.
        public var isSampled: Bool { true }

        // MARK: Required Segment Fields

        /// A 64-bit identifier for the segment, unique among segments in the same trace, in **16 hexadecimal digits**.
        internal var id: ID { lock.withReaderLock { _id } }

        /// The logical name of the service that handled the request, up to **200 characters**.
        /// For example, your application's name or domain name.
        /// Names can contain Unicode letters, numbers, and whitespace, and the following symbols: _, ., :, /, %, &, #, =, +, \, -, @
        internal var name: String { lock.withReaderLock { _name } }

        #if false // part of _context
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
        private var traceId: TraceID { lock.withReaderLock { _context.traceId } }
        #endif
        internal var _test_traceId: TraceID { lock.withReaderLock { _context.traceId } }

        #if false // part of _state
        /// **number** that is the time the segment was created, in floating point seconds in epoch time.
        /// For example, 1480615200.010 or 1.480615200010E9.
        /// Use as many decimal places as you need. Microsecond resolution is recommended when available.
        internal var startTime: Timestamp { lock.withReaderLock { _state.startTime } }

        /// **number** that is the time the segment was closed.
        /// For example, 1480615200.090 or 1.480615200090E9.
        /// Specify either an end_time or in_progress.
        internal var endTime: Timestamp? { lock.withReaderLock { _state.endTime } }

        /// **boolean**, set to true instead of specifying an end_time to record that a segment is started, but is not complete.
        /// Send an in-progress segment when your application receives a request that will take a long time to serve, to trace the request receipt.
        /// When the response is sent, send the complete segment to overwrite the in-progress segment.
        /// Only send one complete segment, and one or zero in-progress segments, per request.
        internal var inProgress: Bool { lock.withReaderLock { _state.inProgress } }
        #endif
        internal var _test_startTime: Timestamp { lock.withReaderLock { _state.startTime } }
        internal var _test_inProgress: Bool? { lock.withReaderLock { _state.inProgress ? true : nil } }

        // MARK: Required Subsegment Fields

        /// Required only if sending a subsegment separately.
        private let type: SegmentType?

        // MARK: Optional Segment Fields

        #if false // part of _context
        /// A subsegment ID you specify if the request originated from an instrumented application.
        /// The X-Ray SDK adds the parent subsegment ID to the tracing header for downstream HTTP calls.
        /// In the case of nested subsguments, a subsegment can have a segment or a subsegment as its parent.
        ///
        /// # Subsegment
        /// Required only if sending a subsegment separately.
        /// In the case of nested subsegments, a subsegment can have a segment or a subsegment as its parent.
        private var parentId: ID? { lock.withReaderLock { _context.parentId } }
        #endif
        internal var _test_parentId: ID? { lock.withReaderLock { _context.parentId } }

        /// An object with information about your application.
        private let _service: Service?

        /// A string that identifies the user who sent the request.
        private let _user: String?

        /// The type of AWS resource running your application.
        private var _origin: Origin?

        /// http objects with information about the original HTTP request.
        private var _http: HTTP
        internal var _test_http: HTTP { lock.withReaderLock { _http } }

        /// aws object with information about the AWS resource on which your application served the request
        private var _aws: AWS?

        /// **boolean** indicating that a client error occurred (response status code was 4XX Client Error).
        private var _error: Bool?
        /// **boolean** indicating that a request was throttled (response status code was 429 Too Many Requests).
        private var _throttle: Bool?
        /// **boolean** indicating that a server error occurred (response status code was 5XX Server Error).
        private var _fault: Bool?
        internal func _test_error(error: inout Bool?, throttle: inout Bool?, fault: inout Bool?) {
            lock.withReaderLock {
                error = _error
                throttle = _throttle
                fault = _fault
            }
        }

        /// the exception(s) that caused the error.
        private var _cause: Cause = Cause()
        internal var _test_exceptions: [Exception] { lock.withReaderLock { _cause.exceptions } }

        /// annotations object with key-value pairs that you want X-Ray to index for search.
        private var _annotations: Annotations
        internal var _test_annotations: Annotations { lock.withReaderLock { _annotations } }

        /// metadata object with any additional data that you want to store in the segment.
        private var _metadata: Metadata
        internal var _test_metadata: Metadata { lock.withReaderLock { _metadata } }

        /// **array** of subsegment objects.
        private var _subsegments: [Segment] = [Segment]()

        // MARK: Optional Subsegment Fields

        /// `aws` for AWS SDK calls; `remote` for other downstream calls.
        private var _namespace: Namespace?
        internal var _test_namespace: Namespace? { lock.withReaderLock { _namespace } }

        #if false // not used
        /// **array** of subsegment IDs that identifies subsegments with the same parent that completed prior to this subsegment.
        private let _precursorIDs: [String]? = nil
        #endif

        init(
            id: ID,
            name: String,
            context: TraceContext,
            baggage: BaggageContext,
            startTime: Timestamp = Timestamp(),
            subsegment: Bool = false,
            service: Service? = nil, user: String? = nil,
            origin: Origin? = nil, http: HTTP? = nil, aws: AWS? = nil,
            annotations: Annotations? = nil, metadata: Metadata? = nil,
            logger: Logger? = nil,
            callback: StateChangeCallback? = nil
        ) {
            _id = id
            _name = String(Self.validName(name))
            _context = context
            _state = .inProgress(started: startTime)
            _baggage = (try? baggage.withParent(id)) ?? baggage
            type = subsegment && context.parentId != nil ? .subsegment : nil
            _service = service
            _user = user
            _origin = origin
            _http = http ?? HTTP()
            _aws = aws
            _annotations = annotations ?? Annotations()
            _metadata = metadata ?? Metadata()
            self.logger = logger
            _callback = callback
        }

        convenience init(
            id: ID,
            name: String,
            context: TraceContext,
            startTime: Timestamp = Timestamp(),
            subsegment: Bool = false,
            service: Service? = nil, user: String? = nil,
            origin: Origin? = nil, http: HTTP? = nil, aws: AWS? = nil,
            annotations: Annotations? = nil, metadata: Metadata? = nil,
            logger: Logger? = nil,
            callback: StateChangeCallback? = nil
        ) {
            var baggage = BaggageContext()
            baggage.xRayContext = .init(traceId: context.traceId, parentId: id, sampled: context.sampled)
            self.init(id: id, name: name, context: context, baggage: baggage,
                      startTime: startTime, subsegment: subsegment, service: service, user: user,
                      origin: origin, http: http, aws: aws, annotations: annotations, metadata: metadata,
                      logger: logger, callback: callback)
        }

        deinit {
            guard isSampled else { return }
            lock.withReaderLockVoid {
                if _state.hasEmitted == false {
                    logger?.error("Segment \(_id) has not been emitted, current state: \(_state)")
                }
            }
        }

        // MARK: State

        /// Updates `endTime` of the Segment.
        ///
        /// Has no effect if the segment has been already ended or emitted in which case an error will be logged.
        public func end() {
            try? end(Timestamp())
        }

        internal func end(_ timestamp: Timestamp) throws {
            do {
                try lock.withWriterLockVoid {
                    switch _state {
                    case .inProgress(let startTime):
                        guard startTime < timestamp else {
                            throw SegmentError.backToTheFuture
                        }
                        _state = .ended(started: startTime, ended: timestamp)
                    case .ended:
                        throw SegmentError.alreadyEnded
                    case .emitted:
                        throw SegmentError.alreadyEmitted
                    }
                }
            } catch {
                logger?.error("Failed to end segment: \(error)")
                throw error
            }
        }

        internal func emit() throws {
            do {
                try lock.withWriterLockVoid {
                    switch _state {
                    case .inProgress:
                        // for now we limit sending of in-progress segments to subsegments
                        // to make sure that their parent was already emitted
                        throw SegmentError.inProgress
                    case .ended(let started, let ended):
                        let now = Timestamp()
                        _state = .emitted(started: started, ended: ended, emitted: now)
                    case .emitted:
                        throw SegmentError.alreadyEmitted
                    }
                }
            } catch {
                logger?.error("Failed to emit segment: \(error)")
                throw error
            }
        }

        // MARK: Subsegments

        /// Creates new subsegment.
        ///
        /// - Parameters:
        ///   - name: segment name
        ///   - metadata: segment metadata
        public func beginSubsegment(name: String, metadata: XRayRecorder.Segment.Metadata? = nil) -> XRayRecorder.Segment {
            lock.withWriterLock {
                // TODO: document/test/discuss where/how it should be updated and propagated
                // for now the context contain the segment parentId
                // while the baggage contains the segment id to be propagated as parent
                var context = _context
                context.parentId = _id
                let newSegment = XRayRecorder.Segment(
                    id: ID(), name: name,
                    context: context, baggage: _baggage,
                    subsegment: true,
                    metadata: metadata,
                    callback: self._callback
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

        // MARK: Errors and exceptions

        internal func addException(_ exception: Exception) {
            lock.withWriterLockVoid {
                self._error = true
                _cause.exceptions.append(exception)
            }
        }

        /// Records an excaption.
        ///
        /// - Parameters:
        ///   - message: exception message
        ///   - type: excetion type
        public func addException(message: String, type: String? = nil) {
            addException(Exception(message: message, type: type))
        }

        /// Records and error.
        ///
        /// - Parameter error: error
        public func addError(_ error: Error) {
            addException(Exception(error))
        }

        // MARK: HTTP request data

        /// Records details about an HTTP request that your application served (in a segment) or
        /// that your application made to a downstream HTTP API (in a subsegment).
        ///
        /// The IP address of the requester can be retrieved from the IP packet's `Source Address` or, for forwarded requests,
        /// from an `X-Forwarded-For` header.
        ///
        /// Has no effect if the HTTP method is invalid in which case an error will be logged.
        ///
        /// - Parameters:
        ///   - method: The request method. For example, `GET`.
        ///   - url: The full URL of the request, compiled from the protocol, hostname, and path of the request.
        ///   - userAgent: The user agent string from the requester's client.
        ///   - clientIP: The IP address of the requester.
        public func setHTTPRequest(method: String, url: String, userAgent: String? = nil, clientIP: String? = nil) {
            let httpMethod = HTTPMethod(rawValue: method)
            if case HTTPMethod.RAW(let rawValue) = httpMethod {
                logger?.error("Invalid HTTP method: \(rawValue)")
                return
            }
            lock.withWriterLockVoid {
                _namespace = url.contains(".amazonaws.com/") ? .aws : .remote
                _http.request = HTTP.Request(method: method, url: url, userAgent: userAgent, clientIP: clientIP)
            }
        }

        /// Records details about an HTTP response that your application served (in a segment) or
        /// that your application made to a downstream HTTP API (in a subsegment).
        ///
        /// Set one or more of the error fields:
        /// - `error` - if response status code was 4XX Client Error
        /// - `throttle` - if response status code was 429 Too Many Requests
        /// - `fault` - if response status code was 5XX Server Error
        ///
        /// - Parameters:
        ///   - status: HTTP status of the response.
        ///   - contentLength: the length of the response body in bytes.
        public func setHTTPResponse(status: UInt, contentLength: UInt? = nil) {
            lock.withWriterLockVoid {
                _http.response = HTTP.Response(status: status, contentLength: contentLength)

                switch status {
                case 400 ..< 500:
                    _error = true
                case 500 ..< 600:
                    _fault = true
                default:
                    break
                }

                if status == 429 {
                    _throttle = true
                }
            }
        }

        // MARK: Annotations

        internal func setAnnotation(_ value: AnnotationValue, forKey key: String) {
            let key = Self.validAnnotationKey(key)
            lock.withWriterLockVoid {
                _annotations[key] = value
            }
        }

        /// Sets an annotation.
        ///
        /// Keys must be alphanumeric in order to work with filters. Underscore is allowed. Other symbols and whitespace are not allowed.
        ///
        /// X-Ray indexes up to 50 annotations per trace.
        ///
        /// - Parameters:
        ///   - value: annotation value
        ///   - key: annotation key
        public func setAnnotation(_ value: String, forKey key: String) {
            setAnnotation(.string(value), forKey: key)
        }

        /// Sets an annotation.
        ///
        /// Keys must be alphanumeric in order to work with filters. Underscore is allowed. Other symbols and whitespace are not allowed.
        ///
        /// X-Ray indexes up to 50 annotations per trace.
        ///
        /// - Parameters:
        ///   - value: annotation value
        ///   - key: annotation key
        public func setAnnotation(_ value: Bool, forKey key: String) {
            setAnnotation(.bool(value), forKey: key)
        }

        /// Sets an annotation.
        ///
        /// Keys must be alphanumeric in order to work with filters. Underscore is allowed. Other symbols and whitespace are not allowed.
        ///
        /// X-Ray indexes up to 50 annotations per trace.
        ///
        /// - Parameters:
        ///   - value: annotation value
        ///   - key: annotation key
        public func setAnnotation(_ value: Int, forKey key: String) {
            setAnnotation(.integer(value), forKey: key)
        }

        /// Sets an annotation.
        ///
        /// Keys must be alphanumeric in order to work with filters. Underscore is allowed. Other symbols and whitespace are not allowed.
        ///
        /// X-Ray indexes up to 50 annotations per trace.
        ///
        /// - Parameters:
        ///   - value: annotation value
        ///   - key: annotation key
        public func setAnnotation(_ value: Double, forKey key: String) {
            setAnnotation(.double(value), forKey: key)
        }

        // MARK: Metadata

        /// Sets metadata object.
        ///
        /// Replaces all previously set metadata.
        ///
        /// Keys starting with `AWS.` are reserved for use by AWS-provided SDKs and clients.
        ///
        /// - Parameters:
        ///   - metadata: metadata object
        public func setMetadata(_ metadata: Metadata) {
            // not sure if its worth the effort
            let metadata = Dictionary(uniqueKeysWithValues:
                metadata.map { key, value in (Self.validMetadataKey(key), value) })
            lock.withWriterLockVoid {
                _metadata = metadata
            }
        }

        /// Sets a metadata value.
        ///
        /// Overwrites previous value.
        ///
        /// Keys starting with `AWS.` are reserved for use by AWS-provided SDKs and clients.
        ///
        /// - Parameters:
        ///   - value: metadata value
        ///   - key: metadata key
        public func setMetadata(_ value: AnyEncodable, forKey key: String) {
            let key = Self.validMetadataKey(key)
            lock.withWriterLockVoid {
                _metadata[key] = value
            }
        }

        /// Appends a metadata value.
        ///
        /// Stores the value in a collection, appending to the end of the collection if it already exists.
        ///
        /// Keys starting with `AWS.` are reserved for use by AWS-provided SDKs and clients.
        ///
        /// - Parameters:
        ///   - value: metadata value
        ///   - key: metadata key
        public func appendMetadata(_ value: AnyEncodable, forKey key: String) {
            let key = Self.validMetadataKey(key)
            lock.withWriterLockVoid {
                if var array = _metadata[key]?.value as? [Any] {
                    array.append(value.value)
                    _metadata[key] = AnyEncodable(array)
                } else {
                    _metadata[key] = [value.value]
                }
            }
        }
    }
}

// MARK: - State

private extension XRayRecorder.Segment.State {
    var startTime: Timestamp {
        switch self {
        case .inProgress(let started):
            return started
        case .ended(let started, ended: _):
            return started
        case .emitted(let started, ended: _, emitted: _):
            return started
        }
    }

    var endTime: Timestamp? {
        switch self {
        case .inProgress:
            return nil
        case .ended(started: _, let ended):
            return ended
        case .emitted(started: _, let ended, emitted: _):
            return ended
        }
    }

    var inProgress: Bool {
        endTime == nil
    }

    var hasEmitted: Bool {
        switch self {
        case .inProgress:
            return false
        case .ended:
            return false
        case .emitted:
            return true
        }
    }
}

extension XRayRecorder.Segment.State: Equatable {}

extension XRayRecorder.Segment.State: CustomStringConvertible {
    var description: String {
        switch self {
        case .inProgress:
            return "inProgress"
        case .ended(started: _, let ended):
            return "ended @ \(ended.secondsSinceEpoch)"
        case .emitted(started: _, ended: _, let emitted):
            return "emitted @ \(emitted.secondsSinceEpoch)"
        }
    }
}

// MARK: - Validation

internal extension XRayRecorder.Segment {
    // The logical name of the service that handled the request, up to **200 characters**.
    // Names can contain Unicode letters, numbers, and whitespace, and the following symbols: _, ., :, /, %, &, #, =, +, \, -, @
    static func validName(_ name: String) -> Substring {
        name.prefix(200)
    }

    // Keys must be alphanumeric in order to work with filters. Underscore is allowed.
    // Other symbols and whitespace are not allowed.
    static func validAnnotationKey(_ key: String) -> String {
        key.filter { ("0" ... "9").contains($0) || ("a" ... "z").contains($0) || ("A" ... "Z").contains($0) || $0 == "_" }
    }

    // Keys starting with `AWS.` are reserved for use by AWS-provided SDKs and clients.
    static func validMetadataKey(_ key: String) -> String {
        if key.hasPrefix("AWS.") == false {
            return key
        } else {
            return "_" + key
        }
    }
}

// MARK: - Encodable

private extension KeyedEncodingContainerProtocol {
    mutating func encodeIfNotEmpty<T>(_ object: T, forKey key: Self.Key) throws where T: Sequence, T: Encodable {
        guard object.first(where: { _ in true }) != nil else { return }
        try encode(object, forKey: key)
    }
}

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
            // TODO: no need to encode id and traceId for embedded segments
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(_id, forKey: .id)
            try container.encode(_name, forKey: .name)
            try container.encode(_context.traceId.rawValue, forKey: .traceId)
            try container.encode(_state.startTime, forKey: .startTime)
            // encode either endTime or inProgress
            if let endTime = _state.endTime {
                try container.encode(endTime, forKey: .endTime)
            } else {
                try container.encode(true, forKey: .inProgress)
            }
            try container.encodeIfPresent(type, forKey: .type)
            try container.encodeIfPresent(_context.parentId, forKey: .parentId)
            try container.encodeIfPresent(_service, forKey: .service)
            try container.encodeIfPresent(_user, forKey: .user)
            try container.encodeIfPresent(_origin, forKey: .origin)
            if _http.request != nil || _http.response != nil {
                try container.encode(_http, forKey: .http)
            }
            try container.encodeIfPresent(_aws, forKey: .aws)
            try container.encodeIfPresent(_error, forKey: ._error)
            try container.encodeIfPresent(_throttle, forKey: ._throttle)
            try container.encodeIfPresent(_fault, forKey: ._fault)
            if _cause.exceptions.isEmpty == false {
                try container.encode(_cause, forKey: ._cause)
            }
            try container.encodeIfNotEmpty(_annotations, forKey: ._annotations)
            // do not throw if encoding of AnyCodable failed
            do {
                try container.encodeIfNotEmpty(_metadata, forKey: ._metadata)
            } catch {
                logger?.error("Failed to encode metadata: \(error)")
            }
            try container.encodeIfNotEmpty(_subsegments, forKey: ._subsegments)
            // subsegments only
            if _context.parentId != nil {
                try container.encodeIfPresent(_namespace, forKey: .namespace)
                #if false // not used
                try container.encodeIfPresent(_precursorIDs, forKey: .precursorIDs)
                #endif
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
        case .integer(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        }
    }
}
