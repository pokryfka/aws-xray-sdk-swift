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

import AnyCodable
import AWSXRayRecorder
import Baggage
import Dispatch
import Instrumentation

// TODO: compare with https://github.com/awslabs/aws-xray-sdk-with-opentelemetry/blob/master/sdk/src/main/java/com/amazonaws/xray/opentelemetry/tracing/EntitySpan.java

extension XRayRecorder.Segment: Instrumentation.Span {
    public var operationName: String { name }

    public var kind: SpanKind { .internal }

    public var status: SpanStatus? {
        get { nil } // TODO: getter to be removed
        set(newValue) {
            if let status = newValue {
                setStatus(status)
            }
        }
    }

    public func setStatus(_ status: SpanStatus) {
        // TODO: should the status be set just once?
        guard status.canonicalCode != .ok else { return }
        // note that contrary to what the name may suggest, exceptions are added not set
        setException(message: status.message ?? "\(status.canonicalCode)", type: "\(status.canonicalCode)")
    }

    public var startTimestamp: Timestamp { .now() } // TODO: getter to be removed

    public var endTimestamp: Timestamp? { nil } // TODO: getter to be removed

    public func end(at timestamp: Timestamp) {
        // TODO: setting entTime explicitly is currently not exposed (internal)
        end()
    }

    public var events: [SpanEvent] { [SpanEvent]() } // TODO: getter to be removed

    public func addEvent(_ event: SpanEvent) {
        // XRay segment does not have direct Span Event equivalent
        // Arguably the closest match is a subsegment with startTime == endTime (?)
        // TODO: test different approaches, make it configurable
        beginSubsegment(name: event.name, metadata: nil).end()
        // TODO: set Event attributes once interface is refined
        // we can also store it as metadata as in https://github.com/awslabs/aws-xray-sdk-with-opentelemetry/commit/89f941af2b32844652c190b79328f9f783fe60f8
        appendMetadata("\(event)", forKey: MetadataKeys.events)
    }

    public var attributes: SpanAttributes {
        get { SpanAttributes() } // TODO: getter to be removed
        set(newValue) {}
    }

    // TODO: map HTTP Span Attributes to XRAy Segment HTTP object (needs to be exposed, currently internal)

    public func setAttribute(_ value: String, forKey key: String) {
        setAnnotation(value, forKey: key)
    }

    public func setAttribute(_ value: [String], forKey key: String) {
        setMetadata("\(value)", forKey: MetadataKeys.attribute(key))
    }

    public func setAttribute(_ value: Int, forKey key: String) {
        setAnnotation(value, forKey: key)
    }

    public func setAttribute(_ value: [Int], forKey key: String) {
        setMetadata(AnyEncodable(value), forKey: MetadataKeys.attribute(key))
    }

    public func setAttribute(_ value: Double, forKey key: String) {
        setAnnotation(value, forKey: key)
    }

    public func setAttribute(_ value: [Double], forKey key: String) {
        setMetadata(AnyEncodable(value), forKey: MetadataKeys.attribute(key))
    }

    public func setAttribute(_ value: Bool, forKey key: String) {
        setAnnotation(value, forKey: key)
    }

    public func setAttribute(_ value: [Bool], forKey key: String) {
        setMetadata(AnyEncodable(value), forKey: MetadataKeys.attribute(key))
    }

    public var isRecording: Bool {
        baggage.xRayContext?.sampled == .sampled
    }

    public func addLink(_ link: SpanLink) {
        appendMetadata("\(link)", forKey: MetadataKeys.links)
    }
}

// MARK: -

private enum MetadataKeys {
    static let events = "events"
    static let links = "events"
    static func attribute(_ key: String) -> String { "attr_\(key)" }
}

// TODO: use AnyCodable to box Encodable and CustomStringConvertible values

extension Instrumentation.SpanEvent: CustomStringConvertible {
    public var description: String {
        // TODO: add attributes and timestamp after their types are updated
        "SpanEvent(name: \(name))"
    }
}

extension Instrumentation.SpanLink: CustomStringConvertible {
    public var description: String {
        // TODO: add attributes and timestamp after their types are updated
        "SpanLink(name: \(context))"
    }
}
