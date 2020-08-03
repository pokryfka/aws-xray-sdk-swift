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

public typealias XRayContext = XRayRecorder.TraceContext

extension XRayRecorder {
    enum TraceError: Error {
        case invalidTraceID(String)
        case invalidParentID(String)
        case invalidSampleDecision(String)
        case invalidTracingHeader(String)
        case missingContext
    }

    /// XRay Trace ID used to group `XRayRecorder.Segment`s.
    ///
    /// # Trace ID Format
    /// A `trace_id` consists of three numbers separated by hyphens.
    /// For example, `1-58406520-a006649127e371903a2de979`. This includes:
    /// - The version number, that is, 1.
    /// - The time of the original request, in Unix epoch time, in **8 hexadecimal digits**.
    ///   For example, 10:00AM December 1st, 2016 PST in epoch time is `1480615200` seconds, or `58406520` in hexadecimal digits.
    /// - A 96-bit identifier for the trace, globally unique, in **24 hexadecimal digits**.
    ///
    /// # References
    /// - [Sending trace data to AWS X-Ray - Generating trace IDs](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html#xray-api-traceids)
    public struct TraceID: CustomStringConvertible {
        /// The version number, that is, 1.
        let version: UInt = 1
        /// The time of the original request, in Unix epoch time, in **8 hexadecimal digits**.
        /// For example, 10:00AM December 1st, 2016 PST in epoch time is `1480615200` seconds, or `58406520` in hexadecimal digits.
        let date: String
        /// A 96-bit identifier for the trace, globally unique, in **24 hexadecimal digits**.
        let identifier: String

        public var description: String {
            "\(version)-\(date)-\(identifier)"
        }
    }
}

extension XRayRecorder.TraceID: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(version)
        hasher.combine(date)
        hasher.combine(identifier)
    }
}

extension XRayRecorder.TraceID: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(String(describing: self))
    }
}

// TODO: change TraceID to RawRepresentable?

extension XRayRecorder.TraceID {
    /// Creates new `TraceID`.
    public init() {
        self.init(secondsSinceEpoch: Timestamp().secondsSinceEpoch)
    }

    internal init(secondsSinceEpoch: Double) {
        let value = UInt32(min(Double(UInt32.max), secondsSinceEpoch))
        let dateValue = String(value, radix: 16, uppercase: false)
        let datePadding = String(repeating: "0", count: max(0, 8 - dateValue.count))
        date = "\(datePadding)\(dateValue)"
        identifier = String.random96()
    }

    /// Parses and validates string with `TraceID`.
    ///
    /// - Parameter string: string with `TraceID`.
    /// - Throws: may throw `XRayRecorder.TraceError` if the value is invalid.
    init(string: String) throws {
        let values = string.split(separator: "-")
        guard
            values.count == 3,
            values[0] == "1",
            values[1].count == 8,
            values[2].count == 24,
            Float("0x\(values[1])") != nil,
            Float("0x\(values[2])") != nil
        else {
            throw XRayRecorder.TraceError.invalidTraceID(string)
        }

        date = String(values[1])
        identifier = String(values[2])
    }
}

// TODO: make SampleDecision internal in v0.6.0, change RawRepresentable?

extension XRayRecorder {
    /// Sampling decision.
    internal enum SampleDecision: String, Encodable {
        case sampled = "Sampled=1"
        case notSampled = "Sampled=0"
        case unknown = ""
        case requested = "Sampled=?"

        // "?" is undocummented, spotted in https://github.com/aws/aws-xray-sdk-java/blob/829f4c92f099349dbb14d6efd5c19e8452c3f6bc/aws-xray-recorder-sdk-core/src/main/java/com/amazonaws/xray/entities/TraceHeader.java#L41

        init(_ boolValue: Bool) {
            self = boolValue ? .sampled : .notSampled
        }
    }
}

extension XRayRecorder {
    /// XRay Trace Context propagated in a tracing header.
    ///
    /// # Tracing header
    /// All requests are traced, up to a configurable minimum.
    /// After reaching that minimum, a percentage of requests are traced to avoid unnecessary cost.
    /// The sampling decision and trace ID are added to HTTP requests in **tracing headers** named `X-Amzn-Trace-Id`.
    /// The first X-Ray-integrated service that the request hits adds a tracing header, which is read by the X-Ray SDK and included in the response.
    ///
    /// # Example Tracing header with root trace ID and sampling decision:
    /// ```
    /// X-Amzn-Trace-Id: Root=1-5759e988-bd862e3fe1be46a994272793;Sampled=1
    /// ```
    ///
    /// # Tracing Header Security
    /// A tracing header can originate from the X-Ray SDK, an AWS service, or the client request.
    /// Your application can remove `X-Amzn-Trace-Id` from incoming requests to avoid issues caused by users adding trace IDs
    /// or sampling decisions to their requests.
    ///
    /// The tracing header can also contain a parent segment ID if the request originated from an instrumented application.
    /// For example, if your application calls a downstream HTTP web API with an instrumented HTTP client,
    /// the X-Ray SDK adds the segment ID for the original request to the tracing header of the downstream request.
    /// An instrumented application that serves the downstream request can record the parent segment ID to connect the two requests.
    ///
    /// # Example Tracing header with root trace ID, parent segment ID and sampling decision
    /// ```
    /// X-Amzn-Trace-Id: Root=1-5759e988-bd862e3fe1be46a994272793;Parent=53995c3f42cd8ad8;Sampled=1
    /// ```
    ///
    ///  # References
    /// - [AWS X-Ray concepts - Tracing header](https://docs.aws.amazon.com/xray/latest/devguide/xray-concepts.html#xray-concepts-tracingheader)
    public struct TraceContext {
        /// root trace ID
        public let traceId: TraceID
        /// parent segment ID
        public var parentId: Segment.ID?
        /// sampling decision
        internal var sampled: SampleDecision

        /// True is the `sampled` flag is set, false otherwise.
        var isSampled: Bool {
            sampled == .sampled
        }

        /// Creates new Trace Context.
        /// - parameter traceId: root trace ID
        /// - parameter parentId: parent segment ID
        /// - parameter sampled: sampling decision
        internal init(traceId: XRayRecorder.TraceID, parentId: XRayRecorder.Segment.ID?, sampled: SampleDecision) {
            self.traceId = traceId
            self.parentId = parentId
            self.sampled = sampled
        }

        /// Creates new Trace Context.
        /// - parameter traceId: root trace ID
        /// - parameter parentId: parent segment ID
        /// - parameter sampled: sampling decision
        public init(traceId: TraceID = .init(), parentId: Segment.ID? = nil, sampled: Bool = true) {
            self.traceId = traceId
            self.parentId = parentId
            self.sampled = .init(sampled)
        }
    }
}

extension XRayRecorder.TraceContext {
    /// Parses and validates string with Tracing Header.
    ///
    /// - Parameter string: string with `TraceContext`.
    /// - Throws: may throw `XRayRecorder.TraceError` if the value is invalid.
    public init(tracingHeader: String) throws {
        let values = tracingHeader.split(separator: ";")
        guard
            values.count >= 1, values.count <= 3,
            values[0].starts(with: "Root=")
        else {
            throw XRayRecorder.TraceError.invalidTracingHeader(tracingHeader)
        }

        traceId = try XRayRecorder.TraceID(string: String(values[0].dropFirst("Root=".count)))

        guard values.count > 1 else {
            parentId = nil
            sampled = .unknown
            return
        }

        var valueIndex = 1
        if values[valueIndex].starts(with: "Parent=") {
            let string = String(values[1].dropFirst("Parent=".count))
            guard let parentIdValue = XRayRecorder.Segment.ID(rawValue: string) else {
                throw XRayRecorder.TraceError.invalidParentID(string)
            }
            parentId = parentIdValue
            valueIndex += 1
        } else {
            parentId = nil
        }

        if valueIndex < values.count {
            guard
                let value = XRayRecorder.SampleDecision(rawValue: String(values[valueIndex]))
            else {
                throw XRayRecorder.TraceError.invalidTracingHeader(tracingHeader)
            }
            sampled = value
        } else {
            sampled = .unknown
        }
    }

    /// Tracing header value.
    public var tracingHeader: String {
        let segments: [String?] = [
            "Root=\(traceId)",
            {
                guard let parentId = parentId else { return nil }
                return "Parent=\(parentId.rawValue)"
            }(),
            {
                guard sampled != .unknown else { return nil }
                return sampled.rawValue
            }(),
        ]
        return segments.compactMap { $0 }.joined(separator: ";")
    }
}

extension XRayRecorder.TraceContext: Equatable {}
