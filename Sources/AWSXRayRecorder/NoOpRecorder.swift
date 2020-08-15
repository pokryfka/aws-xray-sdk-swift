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

// TODO: just like with NoOpSegment we could reduce allocations by having a base class

/// No operation `XRayRecorder` used when no recording is required.
public class XRayNoOpRecorder: XRayRecorder {
    /// Creates an instance of `XRayNoOpRecorder`.
    public init() {
        super.init(emitter: XRayNoOpEmitter(),
                   logger: Logger(label: "XRayNoOpRecorder", factory: { _ in Logging.SwiftLogNoOpLogHandler() }),
                   config: .init(enabled: false))
    }

    override public func beginSegment(name: String, context: TraceContext, metadata: Segment.Metadata? = nil) -> Segment {
        var baggage = BaggageContext()
        baggage.xRayContext = context
        return NoOpSegment(id: .init(), name: name, baggage: baggage)
    }

    override public func beginSegment(name: String, baggage: BaggageContext, metadata: Segment.Metadata? = nil) -> Segment {
        NoOpSegment(id: .init(), name: name, baggage: baggage)
    }

    override public func wait(_ callback: ((Error?) -> Void)? = nil) {
        callback?(nil)
    }

    override public func shutdown(_ callback: ((Error?) -> Void)? = nil) {
        callback?(nil)
    }
}
