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

// TODO: reduce allocation by by making Segment an abstract class extended by NoOpSegment and DoOpSegment ?

extension XRayRecorder {
    internal class NoOpSegment: Segment {
        override public var isSampled: Bool { false }

        override private init(
            id: ID,
            name: String,
            context: TraceContext,
            baggage: BaggageContext,
            startTime: XRayRecorder.Timestamp = Timestamp(),
            subsegment: Bool = false,
            service: Service? = nil, user: String? = nil,
            origin: Origin? = nil, http: HTTP? = nil, aws: AWS? = nil,
            annotations: Annotations? = nil, metadata: Metadata? = nil,
            logger: Logger? = nil,
            callback: StateChangeCallback? = nil
        ) {
            fatalError()
        }

        init(id: ID, name: String, baggage: BaggageContext, startTime: Timestamp = .now(), logger: Logger? = nil) {
            // the context is not of much importance as the segment will not be emitted
            // however pass the baggage which may contain more than just the X-Ray trace
            let context = baggage.xRayContext ?? XRayRecorder.TraceContext()
            super.init(id: id, name: name, context: context, baggage: baggage, startTime: startTime, logger: logger)
        }

        override func end() {}
        override func end(_: XRayRecorder.Timestamp) throws { assertionFailure() }
        override func emit() throws { assertionFailure() }

        override func beginSubsegment(name: String, startTime: XRayRecorder.Timestamp = .now(),
                                      metadata: XRayRecorder.Segment.Metadata? = nil) -> XRayRecorder.Segment
        {
            NoOpSegment(id: ID(), name: name, baggage: baggage)
        }

        override func subsegmentsInProgress() -> [XRayRecorder.Segment] { [XRayRecorder.Segment]() }

        override func addException(_: Exception) { assertionFailure() }
        override func addException(message: String, type: String? = nil) {}
        override func addError(_: Error) {}

        override func setHTTPRequest(method: String, url: String, userAgent: String? = nil, clientIP: String? = nil) {}
        override func setHTTPResponse(status: UInt, contentLength: UInt? = nil) {}

        override func setAnnotation(_ value: AnnotationValue, forKey key: String) { assertionFailure() }
        override func setAnnotation(_ value: String, forKey key: String) {}
        override func setAnnotation(_ value: Bool, forKey key: String) {}
        override func setAnnotation(_ value: Int, forKey key: String) {}
        override func setAnnotation(_ value: Double, forKey key: String) {}

        override func setMetadata(_: Metadata) {}
        override func setMetadata(_ value: AnyEncodable, forKey key: String) {}
        override func appendMetadata(_ value: AnyEncodable, forKey key: String) {}
    }
}
