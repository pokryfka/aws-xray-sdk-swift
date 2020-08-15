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
    private enum AnnotationKeys {
        static let status = "status"
    }

    private enum MetadataKeys {
        static let events = "events"
    }

    public var operationName: String { name }

    public var kind: SpanKind { .internal }

    public var status: TracingInstrumentation.SpanStatus? {
        get { nil } // not supported
        set(newValue) {
            if let status = newValue {
                setStatus(status)
            }
        }
    }

    public func setStatus(_ status: TracingInstrumentation.SpanStatus) {
        guard status.canonicalCode != .ok else { return }
        // TODO: map to HTTP?
        let message: String = ["\(status.canonicalCode)", status.message].compactMap { $0 }.joined(separator: ": ")
        setAnnotation(message, forKey: AnnotationKeys.status)
        addException(message: message, type: "\(status.canonicalCode)")
    }

    public var startTimestamp: Timestamp { .now() } // not supported
    public var endTimestamp: Timestamp? { nil } // not supported

    public var context: BaggageContext { baggage }

    public func addEvent(_ event: TracingInstrumentation.SpanEvent) {
        // X-Ray segment does not have direct Span Event equivalent
        // Arguably the closest match is a subsegment with startTime == endTime (?)
        beginSubsegment(name: event.name).end()
        // TODO: set Event attributes once interface is refined
        // we can also store it as metadata as in https://github.com/awslabs/aws-xray-sdk-with-opentelemetry/commit/89f941af2b32844652c190b79328f9f783fe60f8
        appendMetadata("\(event)", forKey: MetadataKeys.events)
    }

    public func recordError(_ error: Error) {
        addError(error)
    }

    public var attributes: SpanAttributes {
        get { SpanAttributes() } // not supported
        set(newValue) {
            newValue.forEach { key, value in
                switch value {
                case .string(let value):
                    setAnnotation(value, forKey: key)
                case .stringConvertible(let value):
                    setAnnotation(String(describing: value), forKey: key)
                case .bool(let value):
                    setAnnotation(value, forKey: key)
                case .int(let value):
                    setAnnotation(value, forKey: key)
                case .double(let value):
                    setAnnotation(value, forKey: key)
                default:
                    break
                }
            }
        }
    }

    public var isRecording: Bool { isSampled }

    public func addLink(_: TracingInstrumentation.SpanLink) {
        // not supported
    }

    public func end(at _: Timestamp) {
        end()
    }
}

// MARK: -

extension TracingInstrumentation.SpanEvent: CustomStringConvertible {
    public var description: String {
        "SpanEvent(name: \(name), timestamp: \(timestamp.description)"
    }
}
