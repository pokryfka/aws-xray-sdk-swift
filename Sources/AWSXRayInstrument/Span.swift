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

import AWSXRayRecorder
import Baggage
import Instrumentation
import TracingInstrumentation

// TODO: compare with https://github.com/awslabs/aws-xray-sdk-with-opentelemetry/blob/master/sdk/src/main/java/com/amazonaws/xray/opentelemetry/tracing/EntitySpan.java

extension XRayRecorder.Segment: TracingInstrumentation.Span {
    public var operationName: String { "TODO: name" } // TODO: expose name

    public var kind: SpanKind { .internal }

    /// Getter is not supported.
    public var status: TracingInstrumentation.SpanStatus? {
        get { nil }
        set(newValue) {
            if let status = newValue {
                setStatus(status)
            }
        }
    }

    public func setStatus(_ status: TracingInstrumentation.SpanStatus) {
        guard status.canonicalCode != .ok else { return }
        // TODO: map to HTTP?
        addException(message: status.message ?? "\(status.canonicalCode)", type: "\(status.canonicalCode)")
    }

    /// Not supported.
    public var startTimestamp: Timestamp { .now() }
    /// Not supported.
    public var endTimestamp: Timestamp? { nil }

    public var context: BaggageContext { baggage }

    /// Not supported.
    public var events: [SpanEvent] { [SpanEvent]() }

    public func addEvent(_ event: TracingInstrumentation.SpanEvent) {
        // XRay segment does not have direct Span Event equivalent
        // Arguably the closest match is a subsegment with startTime == endTime (?)
        beginSubsegment(name: event.name, metadata: nil).end()
        // TODO: set Event attributes once interface is refined
        // we can also store it as metadata as in https://github.com/awslabs/aws-xray-sdk-with-opentelemetry/commit/89f941af2b32844652c190b79328f9f783fe60f8
        appendMetadata("\(event)", forKey: MetadataKeys.events)
    }

    public func recordError(_ error: Error) {
        addError(error)
    }

    /// Getter not supported
    public var attributes: SpanAttributes {
        get { SpanAttributes() }
        set(newValue) {}
    }

    public var isRecording: Bool { isSampled }

    public func addLink(_ link: TracingInstrumentation.SpanLink) {
        appendMetadata("\(link)", forKey: MetadataKeys.links)
    }

    public func end(at _: Timestamp) {
        end()
    }
}

// MARK: -

private enum MetadataKeys {
    static let events = "events"
    static let links = "links"
    static func attribute(_ key: String) -> String { "attr_\(key)" }
}

// TODO: use AnyCodable to box Encodable and CustomStringConvertible values

extension TracingInstrumentation.SpanEvent: CustomStringConvertible {
    public var description: String {
        // TODO: add attributes and timestamp after their types are updated
        "SpanEvent(name: \(name))"
    }
}

extension TracingInstrumentation.SpanLink: CustomStringConvertible {
    public var description: String {
        // TODO: add attributes and timestamp after their types are updated
        "SpanLink(name: \(context))"
    }
}
